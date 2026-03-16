export async function requestOpenAIReply(
  apiKey: string,
  messages: Array<{ role: string; content: string }>,
): Promise<string> {
  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      messages,
      temperature: 0.4,
      max_tokens: 220,
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`OpenAI request failed: ${response.status} ${text}`);
  }

  const data = await response.json();
  const reply = data?.choices?.[0]?.message?.content;

  if (typeof reply !== "string" || !reply.trim()) {
    throw new Error("OpenAI returned an empty reply");
  }

  return reply.trim();
}
