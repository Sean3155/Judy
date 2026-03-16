import type { ChatInput } from "./judy_prompt_builder.ts";
import { parseDecisionFrame } from "./decision_frame_parser.ts";
import { extractLatentSignals } from "./latent_signal_extractor.ts";
import { evaluateMemoryWorthiness } from "./memory_worthiness.ts";
import { refreshMemoryProfile, upsertMemoryCandidates } from "./memory_repository.ts";
import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

export async function runAsyncMemoryLearning(params: {
  client: SupabaseClient;
  userId: string;
  input: ChatInput;
  assistantReply: string;
}): Promise<void> {
  const { client, userId, input, assistantReply } = params;

  const decisionFrame = parseDecisionFrame(input);
  const episode = {
    user_message: input.user_message,
    assistant_reply: assistantReply,
    recent_messages: input.recent_messages ?? [],
    weather_snapshot: input.weather_snapshot,
  };

  const latentCandidates = extractLatentSignals(decisionFrame, episode);
  const scoredCandidates = latentCandidates.map((candidate) => ({
    candidate,
    worthiness: evaluateMemoryWorthiness(candidate),
  }));

  const persisted = scoredCandidates.filter((entry) =>
    entry.worthiness.classification === "confirmed_memory" ||
    entry.worthiness.classification === "tentative_memory" ||
    entry.worthiness.classification === "session_only"
  );

  if (persisted.length === 0) return;

  await upsertMemoryCandidates(client, userId, persisted);
  await refreshMemoryProfile(client, userId);
}
