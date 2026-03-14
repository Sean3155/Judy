import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { buildJudyWeatherContext } from "../_shared/weather_context_builder.ts";

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

  const openWeatherApiKey = Deno.env.get("OPENWEATHER_API_KEY");
  if (!openWeatherApiKey) {
    return json({ error: "OPENWEATHER_API_KEY is not configured" }, 500);
  }

  let payload: { latitude?: number; longitude?: number };
  try {
    payload = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const latitude = Number(payload.latitude);
  const longitude = Number(payload.longitude);

  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    return json({ error: "latitude and longitude must be numbers" }, 400);
  }

  try {
    const context = await buildJudyWeatherContext(
      latitude,
      longitude,
      openWeatherApiKey,
    );

    return json(context, 200);
  } catch (error) {
    console.error("weather-context error", error);
    return json({ error: "Failed to build weather context" }, 502);
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
