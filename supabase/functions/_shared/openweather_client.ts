export interface OpenWeatherCurrent {
  temperature: number;
  feelsLike: number;
  humidity: number;
  windSpeed: number;
  windGust: number;
  condition: string;
  visibility: number;
  hasRainOrSnow: boolean;
}

export async function fetchOpenWeatherSnapshot(
  latitude: number,
  longitude: number,
  apiKey: string,
): Promise<OpenWeatherCurrent> {
  const weatherUrl = new URL("https://api.openweathermap.org/data/2.5/weather");
  weatherUrl.searchParams.set("lat", String(latitude));
  weatherUrl.searchParams.set("lon", String(longitude));
  weatherUrl.searchParams.set("units", "metric");
  weatherUrl.searchParams.set("appid", apiKey);

  const response = await fetch(weatherUrl);
  if (!response.ok) {
    throw new Error(`OpenWeather weather request failed: ${response.status}`);
  }

  const data = await response.json();
  const description = String(data?.weather?.[0]?.description ?? "").toLowerCase();

  return {
    temperature: Number(data?.main?.temp ?? 0),
    feelsLike: Number(data?.main?.feels_like ?? data?.main?.temp ?? 0),
    humidity: Number(data?.main?.humidity ?? 0),
    windSpeed: Number(data?.wind?.speed ?? 0),
    windGust: Number(data?.wind?.gust ?? data?.wind?.speed ?? 0),
    condition: description,
    visibility: Number(data?.visibility ?? 0),
    hasRainOrSnow:
      description.includes("rain") ||
      description.includes("drizzle") ||
      description.includes("snow") ||
      description.includes("storm"),
  };
}

export async function fetchPrecipitationProbability(
  latitude: number,
  longitude: number,
  apiKey: string,
): Promise<number> {
  const forecastUrl = new URL("https://api.openweathermap.org/data/2.5/forecast");
  forecastUrl.searchParams.set("lat", String(latitude));
  forecastUrl.searchParams.set("lon", String(longitude));
  forecastUrl.searchParams.set("units", "metric");
  forecastUrl.searchParams.set("cnt", "1");
  forecastUrl.searchParams.set("appid", apiKey);

  const response = await fetch(forecastUrl);
  if (!response.ok) {
    throw new Error(`OpenWeather forecast request failed: ${response.status}`);
  }

  const data = await response.json();
  const pop = Number(data?.list?.[0]?.pop ?? 0);
  if (Number.isNaN(pop)) return 0;
  return Math.max(0, Math.min(1, pop));
}
