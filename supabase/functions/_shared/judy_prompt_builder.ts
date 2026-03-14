import type { JudyWeatherContext } from "./weather_context_builder.ts";

export interface RecentMessage {
  role: "user" | "assistant";
  text: string;
}

export interface ChatInput {
  modality: "text";
  user_message: string;
  weather_snapshot: JudyWeatherContext["weather_snapshot"];
  recent_messages?: RecentMessage[];
}

export function buildJudyMessages(input: ChatInput) {
  const compactHistory = (input.recent_messages ?? [])
    .slice(-6)
    .map((m) => ({ role: m.role, content: m.text.slice(0, 280) }));

  const weatherContext = JSON.stringify(input.weather_snapshot);

  const system = {
    role: "system",
    content:
      [
        "You are Judy, a concise conversational weather assistant.",
        "Use only the provided weather context.",
        "Do not invent weather values or conditions.",
        "Give practical recommendations for clothing, comfort, and short outdoor decisions.",
        "If uncertainty exists, state it briefly.",
        "Keep replies short (2-5 sentences) and helpful.",
      ].join(" "),
  };

  const context = {
    role: "system",
    content: `Current weather context: ${weatherContext}`,
  };

  const user = {
    role: "user",
    content: input.user_message,
  };

  return [system, context, ...compactHistory, user];
}
