import type { DecisionFrame, MemoryItemRecord } from "./memory_types.ts";

export function buildMemoryPromptInjection(
  decisionFrame: DecisionFrame,
  memories: MemoryItemRecord[],
): string | null {
  if (memories.length === 0) return null;

  const lines = memories.slice(0, 6).map((memory, index) => {
    const compactValue = compact(memory.value);
    return `${index + 1}. [${memory.category}] ${memory.key} -> ${compactValue} (conf=${memory.confidence.toFixed(2)})`;
  });

  return [
    "Relevant long-term user memory (user-scoped):",
    `Decision frame primary intent: ${decisionFrame.primary_intent}.`,
    ...lines,
    "Use memory as soft personalization signals. Do not treat tentative memories as facts.",
  ].join(" ");
}

function compact(value: Record<string, unknown>): string {
  const json = JSON.stringify(value);
  if (json.length <= 180) return json;
  return `${json.slice(0, 177)}...`;
}
