import type { JudyWeatherContext } from "./weather_context_builder.ts";
import type { RecentMessage } from "./judy_prompt_builder.ts";

export interface DecisionFrame {
  primary_intent: string;
  secondary_intents: string[];
  decision_object: string;
  constraints: string[];
  evaluation_frame: string[];
  situational_context: string[];
  desired_answer_shape: string;
}

export interface LatentSignalCandidate {
  category: string;
  key: string;
  value: Record<string, unknown>;
  confidence: number;
  source_type: string;
  sensitivity_level: string | null;
}

export interface MemoryWorthiness {
  utility_for_future_advice: number;
  durability_over_time: number;
  role_relevance_to_judy: number;
  confidence: number;
  sensitivity_risk: number;
  classification: "confirmed_memory" | "tentative_memory" | "session_only" | "discard";
}

export interface MemoryItemRecord {
  id: string;
  user_id: string;
  category: string;
  key: string;
  value: Record<string, unknown>;
  confidence: number;
  status: "confirmed_memory" | "tentative_memory" | "session_only" | "discard";
  source_type: string;
  last_reinforced_at: string;
  expires_at: string | null;
  sensitivity_level: string | null;
}

export interface ConversationEpisodeInput {
  user_message: string;
  assistant_reply: string;
  recent_messages: RecentMessage[];
  weather_snapshot: JudyWeatherContext["weather_snapshot"];
}
