import { createClient, type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import type { DecisionFrame, LatentSignalCandidate, MemoryItemRecord, MemoryWorthiness } from "./memory_types.ts";

const MEMORY_TABLE = "user_memory_items";
const PROFILE_TABLE = "user_memory_profile";

type AuthenticatedClient = SupabaseClient;

export async function authenticateUserFromRequest(req: Request): Promise<{
  client: AuthenticatedClient | null;
  userId: string | null;
}> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const authorization = req.headers.get("Authorization") ?? req.headers.get("authorization") ?? "";

  if (!supabaseUrl || !anonKey || !authorization) {
    return { client: null, userId: null };
  }

  const client = createClient(supabaseUrl, anonKey, {
    global: {
      headers: {
        Authorization: authorization,
      },
    },
  });

  const { data, error } = await client.auth.getUser();
  if (error || !data.user) {
    return { client: null, userId: null };
  }

  return { client, userId: data.user.id };
}

export async function fetchRelevantMemoryItems(
  client: AuthenticatedClient,
  userId: string,
  decisionFrame: DecisionFrame,
  limit = 8,
): Promise<MemoryItemRecord[]> {
  const { data, error } = await client
    .from(MEMORY_TABLE)
    .select("id,user_id,category,key,value,confidence,status,source_type,last_reinforced_at,expires_at,sensitivity_level")
    .eq("user_id", userId)
    .in("status", ["confirmed_memory", "tentative_memory"])
    .order("last_reinforced_at", { ascending: false })
    .limit(60);

  if (error || !data) {
    console.error("memory retrieval failed", error);
    return [];
  }

  const now = Date.now();
  const activeItems = data.filter((item) => {
    if (!item.expires_at) return true;
    const expiresMs = Date.parse(item.expires_at as string);
    return Number.isFinite(expiresMs) ? expiresMs > now : true;
  });

  const scored = activeItems
    .map((item) => ({ item: item as MemoryItemRecord, score: relevanceScore(item as MemoryItemRecord, decisionFrame) }))
    .filter(({ score }) => score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map(({ item }) => item);

  return scored;
}

export async function upsertMemoryCandidates(
  client: AuthenticatedClient,
  userId: string,
  candidates: Array<{ candidate: LatentSignalCandidate; worthiness: MemoryWorthiness }>,
): Promise<void> {
  const now = new Date().toISOString();

  for (const { candidate, worthiness } of candidates) {
    if (worthiness.classification === "discard") continue;

    const { data: existing, error: existingError } = await client
      .from(MEMORY_TABLE)
      .select("id,confidence,value")
      .eq("user_id", userId)
      .eq("category", candidate.category)
      .eq("key", candidate.key)
      .limit(20);

    if (existingError) {
      console.error("memory lookup failed", existingError);
      continue;
    }

    const matchedExisting = (existing ?? []).find((record) =>
      JSON.stringify(record.value ?? {}) === JSON.stringify(candidate.value)
    );

    if (matchedExisting?.id) {
      const reinforcedConfidence = reinforceConfidence(matchedExisting.confidence ?? 0.5, candidate.confidence);
      const { error: updateError } = await client
        .from(MEMORY_TABLE)
        .update({
          confidence: reinforcedConfidence,
          status: promoteStatus(worthiness.classification, reinforcedConfidence),
          last_reinforced_at: now,
          source_type: candidate.source_type,
          sensitivity_level: candidate.sensitivity_level,
        })
        .eq("id", matchedExisting.id)
        .eq("user_id", userId);

      if (updateError) {
        console.error("memory reinforcement update failed", updateError);
      }

      continue;
    }

    const { error: insertError } = await client
      .from(MEMORY_TABLE)
      .insert({
        user_id: userId,
        category: candidate.category,
        key: candidate.key,
        value: candidate.value,
        confidence: candidate.confidence,
        status: worthiness.classification,
        source_type: candidate.source_type,
        last_reinforced_at: now,
        sensitivity_level: candidate.sensitivity_level,
      });

    if (insertError) {
      console.error("memory insert failed", insertError);
    }
  }
}

export async function refreshMemoryProfile(
  client: AuthenticatedClient,
  userId: string,
): Promise<void> {
  const { data, error } = await client
    .from(MEMORY_TABLE)
    .select("category,key,value,confidence,status")
    .eq("user_id", userId)
    .in("status", ["confirmed_memory", "tentative_memory"])
    .order("confidence", { ascending: false })
    .limit(40);

  if (error || !data) {
    console.error("memory profile fetch failed", error);
    return;
  }

  const byCategory = new Map<string, string[]>();
  for (const item of data) {
    const list = byCategory.get(item.category) ?? [];
    list.push(memoryLine(item.key, item.value as Record<string, unknown>, Number(item.confidence ?? 0)));
    byCategory.set(item.category, list);
  }

  const payload = {
    user_id: userId,
    style_summary: summarize(byCategory.get("style_preference") ?? []),
    wardrobe_summary: summarize(byCategory.get("wardrobe") ?? []),
    weather_behavior_summary: summarize([
      ...(byCategory.get("weather_annoyance") ?? []),
      ...(byCategory.get("comfort_preference") ?? []),
    ]),
    outing_context_summary: summarize(byCategory.get("outing_context") ?? []),
    updated_at: new Date().toISOString(),
  };

  const { error: upsertError } = await client
    .from(PROFILE_TABLE)
    .upsert(payload, { onConflict: "user_id" });

  if (upsertError) {
    console.error("memory profile upsert failed", upsertError);
  }
}

function relevanceScore(item: MemoryItemRecord, frame: DecisionFrame): number {
  let score = Number(item.confidence ?? 0.5);

  if (frame.primary_intent.includes("clothing") && item.category === "wardrobe") score += 0.35;
  if (frame.primary_intent.includes("outing") && item.category === "outing_context") score += 0.35;
  if (frame.evaluation_frame.includes("comfort") && item.category === "comfort_preference") score += 0.30;
  if (frame.evaluation_frame.includes("weather_risk") && item.category === "weather_annoyance") score += 0.32;

  if (frame.constraints.some((constraint) => item.key.includes(constraint.split("_")[0]))) {
    score += 0.18;
  }

  if (item.status === "confirmed_memory") score += 0.12;

  return score;
}

function reinforceConfidence(existing: number, incoming: number): number {
  const blended = existing * 0.78 + incoming * 0.22;
  return Number(Math.max(0, Math.min(1, blended + 0.02)).toFixed(3));
}

function promoteStatus(
  currentClassification: MemoryWorthiness["classification"],
  confidence: number,
): "confirmed_memory" | "tentative_memory" | "session_only" {
  if (confidence >= 0.74) return "confirmed_memory";
  if (currentClassification === "session_only") return "session_only";
  return "tentative_memory";
}

function summarize(lines: string[]): string | null {
  if (lines.length === 0) return null;
  return lines.slice(0, 4).join(" | ");
}

function memoryLine(key: string, value: Record<string, unknown>, confidence: number): string {
  return `${key}: ${JSON.stringify(value)} (c=${confidence.toFixed(2)})`;
}
