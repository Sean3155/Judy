import type { ConversationEpisodeInput, DecisionFrame, LatentSignalCandidate } from "./memory_types.ts";

export function extractLatentSignals(
  decisionFrame: DecisionFrame,
  episode: ConversationEpisodeInput,
): LatentSignalCandidate[] {
  const userText = episode.user_message.toLowerCase();
  const historyUserTurns = episode.recent_messages
    .filter((m) => m.role === "user")
    .map((m) => m.text.toLowerCase());

  const candidates: LatentSignalCandidate[] = [];

  if (decisionFrame.primary_intent === "clothing_decision") {
    candidates.push(candidate("wardrobe", "decision_frequency", {
      pattern: "user_often_requests_clothing_guidance",
      evidence: compactEvidence([episode.user_message, ...historyUserTurns]),
    }, 0.62));
  }

  if (decisionFrame.constraints.includes("wind_management")) {
    candidates.push(candidate("weather_annoyance", "wind_disruption_tolerance", {
      preference: "low_tolerance_for_wind_disruption",
      weather_cues: {
        wind_speed: episode.weather_snapshot.wind_speed,
        wind_gust: episode.weather_snapshot.wind_gust,
      },
    }, 0.66));
  }

  if (decisionFrame.constraints.includes("rain_exposure_management")) {
    candidates.push(candidate("weather_annoyance", "rain_exposure_preference", {
      preference: "prefers_staying_dry",
      precipitation_probability: episode.weather_snapshot.precipitation_probability,
    }, 0.68));
  }

  if (decisionFrame.situational_context.includes("recurring_outdoor_exposure")) {
    candidates.push(candidate("outing_context", "outdoor_exposure_pattern", {
      signal: "recurring_outdoor_mobility",
      confidence_basis: "repeated_user_mentions",
    }, reinforcementAdjustedConfidence(historyUserTurns, ["walk", "commute", "outside"], 0.58)));
  }

  if (decisionFrame.evaluation_frame.includes("aesthetics")) {
    candidates.push(candidate("style_preference", "comfort_aesthetic_tradeoff", {
      tendency: "balances_style_with_weather_function",
      answer_shape: decisionFrame.desired_answer_shape,
    }, 0.57));
  }

  if (decisionFrame.secondary_intents.includes("social_appropriateness_sensitive")) {
    candidates.push(candidate("social_context", "situational_appropriateness", {
      tendency: "cares_about_context_appropriate_outfits",
    }, 0.63));
  }

  if (decisionFrame.constraints.includes("cold_sensitivity")) {
    candidates.push(candidate("comfort_preference", "thermal_preference", {
      tendency: "cold_sensitive",
      observed_feels_like: episode.weather_snapshot.feels_like,
    }, 0.64));
  }

  return dedupeCandidates(candidates);
}

function candidate(
  category: string,
  key: string,
  value: Record<string, unknown>,
  confidence: number,
): LatentSignalCandidate {
  return {
    category,
    key,
    value,
    confidence,
    source_type: "latent_signal_extractor_v1",
    sensitivity_level: null,
  };
}

function reinforcementAdjustedConfidence(history: string[], reinforcementTerms: string[], base: number): number {
  const score = history.reduce((count, message) => {
    return count + (reinforcementTerms.some((term) => message.includes(term)) ? 1 : 0);
  }, 0);

  return clamp(base + Math.min(0.18, score * 0.04));
}

function compactEvidence(messages: string[]): string[] {
  return messages.slice(-3).map((m) => m.slice(0, 140));
}

function dedupeCandidates(candidates: LatentSignalCandidate[]): LatentSignalCandidate[] {
  const seen = new Set<string>();

  return candidates.filter((candidate) => {
    const fingerprint = `${candidate.category}::${candidate.key}::${JSON.stringify(candidate.value)}`;
    if (seen.has(fingerprint)) return false;
    seen.add(fingerprint);
    return true;
  });
}

function clamp(value: number): number {
  return Math.max(0, Math.min(1, Number(value.toFixed(3))));
}
