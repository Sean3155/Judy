import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { buildJudyMessages, type ChatInput } from "../_shared/judy_prompt_builder.ts";
import { requestOpenAIReply } from "../_shared/openai_client.ts";
import { parseDecisionFrame } from "../_shared/decision_frame_parser.ts";
import {
  authenticateUserFromRequest,
  fetchRelevantMemoryItems,
} from "../_shared/memory_repository.ts";
import { buildMemoryPromptInjection } from "../_shared/memory_retrieval.ts";
import { runAsyncMemoryLearning } from "../_shared/memory_async_pipeline.ts";

declare const EdgeRuntime:
  | {
    waitUntil: (promise: Promise<unknown>) => void;
  }
  | undefined;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const openAiApiKey = Deno.env.get("OPENAI_API_KEY");
  if (!openAiApiKey) {
    return json({ error: "OPENAI_API_KEY is not configured" }, 500);
  }

  let payload: ChatInput;
  try {
    payload = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  if (payload.modality !== "text") {
    return json({ error: "Only text modality is currently supported" }, 400);
  }

  if (!payload.user_message || !payload.user_message.trim()) {
    return json({ error: "user_message is required" }, 400);
  }

  if (!payload.weather_snapshot || typeof payload.weather_snapshot !== "object") {
    return json({ error: "weather_snapshot is required" }, 400);
  }

  const recentMessages = Array.isArray(payload.recent_messages)
    ? payload.recent_messages.slice(-6)
    : [];

  const normalizedInput: ChatInput = {
    ...payload,
    recent_messages: recentMessages,
  };

  const authContext = await authenticateUserFromRequest(req);
  const decisionFrame = parseDecisionFrame(normalizedInput);

  let memoryContext: string | null = null;
  if (authContext.client && authContext.userId) {
    const relevantMemories = await fetchRelevantMemoryItems(
      authContext.client,
      authContext.userId,
      decisionFrame,
      8,
    );
    memoryContext = buildMemoryPromptInjection(decisionFrame, relevantMemories);
  }

  try {
    const messages = buildJudyMessages(normalizedInput, memoryContext ?? undefined);

    const reply = await requestOpenAIReply(openAiApiKey, messages);

    if (authContext.client && authContext.userId) {
      const learningPromise = runAsyncMemoryLearning({
        client: authContext.client,
        userId: authContext.userId,
        input: normalizedInput,
        assistantReply: reply,
      }).catch((error) => {
        console.error("memory async update failed", error);
      });

      if (typeof EdgeRuntime !== "undefined" && typeof EdgeRuntime.waitUntil === "function") {
        EdgeRuntime.waitUntil(learningPromise);
      } else {
        void learningPromise;
      }
    }

    return json({ reply }, 200);
  } catch (error) {
    console.error("chat function error", error);
    return json({ error: "Failed to generate Judy reply" }, 502);
  }
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
