import type { ChatInput } from "./judy_prompt_builder.ts";
import type { DecisionFrame } from "./memory_types.ts";

export function parseDecisionFrame(input: ChatInput): DecisionFrame {
  const text = input.user_message.trim();
  const lowered = text.toLowerCase();

  const intentSignals = inferIntentSignals(lowered);
  const constraints = inferConstraints(lowered, input.weather_snapshot);
  const evaluationFrame = inferEvaluationFrame(lowered, input.weather_snapshot);
  const situationalContext = inferSituationalContext(lowered, input.recent_messages ?? []);

  return {
    primary_intent: intentSignals.primary,
    secondary_intents: intentSignals.secondary,
    decision_object: inferDecisionObject(lowered),
    constraints,
    evaluation_frame: evaluationFrame,
    situational_context: situationalContext,
    desired_answer_shape: inferAnswerShape(lowered),
  };
}

function inferIntentSignals(text: string): { primary: string; secondary: string[] } {
  const secondary: string[] = [];
  let primary = "outdoor_decision_support";

  if (containsAny(text, ["wear", "outfit", "coat", "jacket", "shoes"])) {
    primary = "clothing_decision";
  } else if (containsAny(text, ["walk", "run", "commute", "outside", "go out"])) {
    primary = "outing_feasibility";
  } else if (containsAny(text, ["umbrella", "rain", "wind", "storm", "safe"])) {
    primary = "weather_risk_management";
  }

  if (containsAny(text, ["quick", "short answer", "just tell me"])) {
    secondary.push("concise_output_preference");
  }

  if (containsAny(text, ["why", "because", "reason"])) {
    secondary.push("explanatory_output_preference");
  }

  if (containsAny(text, ["work", "office", "meeting", "formal", "date", "event"])) {
    secondary.push("social_appropriateness_sensitive");
  }

  return { primary, secondary };
}

function inferDecisionObject(text: string): string {
  if (containsAny(text, ["wear", "outfit", "jacket", "coat"])) return "what_to_wear";
  if (containsAny(text, ["walk", "run", "outside", "commute"])) return "whether_and_how_to_go_out";
  if (containsAny(text, ["umbrella", "rain", "wind", "storm"])) return "weather_protection_strategy";
  return "weather_informed_decision";
}

function inferConstraints(text: string, snapshot: ChatInput["weather_snapshot"]): string[] {
  const constraints: string[] = [];

  if (containsAny(text, ["don’t want", "do not want", "avoid"])) {
    constraints.push("avoid_discomfort");
  }
  if (containsAny(text, ["cold", "freezing", "chilly"]) || snapshot.feels_like <= 6) {
    constraints.push("cold_sensitivity");
  }
  if (containsAny(text, ["hot", "sweat", "overheat"]) || snapshot.feels_like >= 27) {
    constraints.push("heat_sensitivity");
  }
  if (containsAny(text, ["wind", "hair", "frizz"]) || snapshot.wind_speed >= 7) {
    constraints.push("wind_management");
  }
  if (containsAny(text, ["rain", "umbrella", "wet"]) || snapshot.precipitation_probability >= 0.45) {
    constraints.push("rain_exposure_management");
  }

  return dedupe(constraints);
}

function inferEvaluationFrame(text: string, snapshot: ChatInput["weather_snapshot"]): string[] {
  const frame: string[] = ["comfort"];

  if (containsAny(text, ["look", "style", "cute", "fit", "formal"])) {
    frame.push("aesthetics");
  }
  if (containsAny(text, ["safe", "slip", "storm", "danger"])) {
    frame.push("safety");
  }
  if (containsAny(text, ["walk", "commute", "travel", "outside"])) {
    frame.push("mobility");
  }
  if (snapshot.precipitation_probability >= 0.6 || snapshot.wind_gust >= 10) {
    frame.push("weather_risk");
  }

  return dedupe(frame);
}

function inferSituationalContext(text: string, history: Array<{ role: string; text: string }>): string[] {
  const context: string[] = [];

  if (containsAny(text, ["today", "now", "right now"])) context.push("immediate_decision_window");
  if (containsAny(text, ["tonight", "later", "this evening"])) context.push("later_time_window");
  if (containsAny(text, ["work", "office", "meeting"])) context.push("workday_context");
  if (containsAny(text, ["date", "friends", "party"])) context.push("social_context");

  const userTurns = history.filter((m) => m.role === "user").map((m) => m.text.toLowerCase());
  if (userTurns.some((m) => containsAny(m, ["walk", "outside", "commute"]))) {
    context.push("recurring_outdoor_exposure");
  }

  return dedupe(context);
}

function inferAnswerShape(text: string): string {
  if (containsAny(text, ["just", "quick", "short"])) return "brief_actionable";
  if (containsAny(text, ["options", "choose", "either"])) return "ranked_options";
  if (containsAny(text, ["why", "explain"])) return "recommendation_plus_reasoning";
  return "concise_recommendation_with_rationale";
}

function containsAny(text: string, terms: string[]): boolean {
  return terms.some((term) => text.includes(term));
}

function dedupe<T>(items: T[]): T[] {
  return [...new Set(items)];
}
