import {
  fetchOpenWeatherSnapshot,
  fetchPrecipitationProbability,
} from "./openweather_client.ts";

export interface WeatherSnapshot {
  temperature: number;
  feels_like: number;
  humidity: number;
  wind_speed: number;
  wind_gust: number;
  precipitation_probability: number;
  condition: string;
  visibility: number;
}

export interface DerivedFlags {
  umbrella_needed: boolean;
  strong_wind_warning: boolean;
  hair_mess_risk: boolean;
  light_jacket_recommended: boolean;
  walk_comfort_score: number;
}

export interface JudyWeatherContext {
  weather_snapshot: WeatherSnapshot;
  derived_flags: DerivedFlags;
}

export async function buildJudyWeatherContext(
  latitude: number,
  longitude: number,
  apiKey: string,
): Promise<JudyWeatherContext> {
  const [snapshot, precipitationProbability] = await Promise.all([
    fetchOpenWeatherSnapshot(latitude, longitude, apiKey),
    fetchPrecipitationProbability(latitude, longitude, apiKey).catch(() => 0),
  ]);

  const weather_snapshot: WeatherSnapshot = {
    temperature: round1(snapshot.temperature),
    feels_like: round1(snapshot.feelsLike),
    humidity: snapshot.humidity,
    wind_speed: round1(snapshot.windSpeed),
    wind_gust: round1(snapshot.windGust),
    precipitation_probability: round2(precipitationProbability),
    condition: snapshot.condition,
    visibility: Math.max(0, Math.round(snapshot.visibility)),
  };

  const walkScore = calculateWalkComfortScore(weather_snapshot);

  const derived_flags: DerivedFlags = {
    umbrella_needed:
      weather_snapshot.precipitation_probability >= 0.45 ||
      snapshot.hasRainOrSnow,
    strong_wind_warning:
      weather_snapshot.wind_speed >= 8 || weather_snapshot.wind_gust >= 12,
    hair_mess_risk:
      weather_snapshot.wind_speed >= 6 || weather_snapshot.wind_gust >= 10,
    light_jacket_recommended:
      weather_snapshot.feels_like <= 16,
    walk_comfort_score: walkScore,
  };

  return { weather_snapshot, derived_flags };
}

function calculateWalkComfortScore(snapshot: WeatherSnapshot): number {
  let score = 100;

  const t = snapshot.feels_like;
  if (t < -5 || t > 32) score -= 35;
  else if (t < 5 || t > 28) score -= 20;
  else if (t < 10 || t > 24) score -= 10;

  if (snapshot.wind_speed >= 8) score -= 25;
  else if (snapshot.wind_speed >= 3) score -= 10;

  if (snapshot.wind_gust >= 12) score -= 8;

  const pop = snapshot.precipitation_probability;
  if (pop >= 0.7) score -= 40;
  else if (pop >= 0.4) score -= 25;
  else if (pop >= 0.2) score -= 10;

  if (snapshot.humidity >= 80 || snapshot.humidity <= 25) score -= 8;

  return Math.max(0, Math.min(100, Math.round(score)));
}

function round1(value: number): number {
  return Number(value.toFixed(1));
}

function round2(value: number): number {
  return Number(value.toFixed(2));
}
