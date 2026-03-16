import type { LatentSignalCandidate, MemoryWorthiness } from "./memory_types.ts";

export function evaluateMemoryWorthiness(candidate: LatentSignalCandidate): MemoryWorthiness {
  const utility = utilityForFutureAdvice(candidate);
  const durability = durabilityOverTime(candidate);
  const roleRelevance = roleRelevanceToJudy(candidate);
  const confidence = candidate.confidence;
  const sensitivityRisk = sensitivityRiskScore(candidate);

  const weighted =
    utility * 0.3 +
    durability * 0.2 +
    roleRelevance * 0.25 +
    confidence * 0.2 -
    sensitivityRisk * 0.15;

  const classification = classify(weighted, confidence, sensitivityRisk);

  return {
    utility_for_future_advice: round3(utility),
    durability_over_time: round3(durability),
    role_relevance_to_judy: round3(roleRelevance),
    confidence: round3(confidence),
    sensitivity_risk: round3(sensitivityRisk),
    classification,
  };
}

function utilityForFutureAdvice(candidate: LatentSignalCandidate): number {
  if (candidate.category === "weather_annoyance") return 0.88;
  if (candidate.category === "comfort_preference") return 0.85;
  if (candidate.category === "wardrobe") return 0.72;
  if (candidate.category === "outing_context") return 0.76;
  return 0.62;
}

function durabilityOverTime(candidate: LatentSignalCandidate): number {
  if (candidate.key.includes("decision_frequency")) return 0.74;
  if (candidate.key.includes("thermal_preference")) return 0.82;
  if (candidate.key.includes("tradeoff")) return 0.68;
  return 0.65;
}

function roleRelevanceToJudy(candidate: LatentSignalCandidate): number {
  if (["weather_annoyance", "comfort_preference", "outing_context"].includes(candidate.category)) {
    return 0.9;
  }
  return 0.7;
}

function sensitivityRiskScore(candidate: LatentSignalCandidate): number {
  if (candidate.sensitivity_level === "high") return 0.9;
  if (candidate.sensitivity_level === "medium") return 0.5;
  return 0.1;
}

function classify(
  weightedScore: number,
  confidence: number,
  sensitivityRisk: number,
): MemoryWorthiness["classification"] {
  if (sensitivityRisk >= 0.8) return "discard";
  if (confidence < 0.45 || weightedScore < 0.45) return "discard";
  if (weightedScore >= 0.75 && confidence >= 0.65) return "confirmed_memory";
  if (weightedScore >= 0.58 && confidence >= 0.55) return "tentative_memory";
  return "session_only";
}

function round3(value: number): number {
  return Number(value.toFixed(3));
}
