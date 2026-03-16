import Foundation

struct ChatWeatherSnapshot: Codable {
    let temperature: Double
    let feelsLike: Double
    let humidity: Int
    let windSpeed: Double
    let windGust: Double
    let precipitationProbability: Double
    let condition: String
    let visibility: Int

    enum CodingKeys: String, CodingKey {
        case temperature
        case feelsLike = "feels_like"
        case humidity
        case windSpeed = "wind_speed"
        case windGust = "wind_gust"
        case precipitationProbability = "precipitation_probability"
        case condition
        case visibility
    }
}

struct WeatherContextResponse: Decodable {
    let weatherSnapshot: ChatWeatherSnapshot
    let derivedFlags: WeatherDerivedFlags

    enum CodingKeys: String, CodingKey {
        case weatherSnapshot = "weather_snapshot"
        case derivedFlags = "derived_flags"
    }
}

struct WeatherDerivedFlags: Decodable {
    let umbrellaNeeded: Bool
    let strongWindWarning: Bool
    let hairMessRisk: Bool
    let lightJacketRecommended: Bool
    let walkComfortScore: Int

    enum CodingKeys: String, CodingKey {
        case umbrellaNeeded = "umbrella_needed"
        case strongWindWarning = "strong_wind_warning"
        case hairMessRisk = "hair_mess_risk"
        case lightJacketRecommended = "light_jacket_recommended"
        case walkComfortScore = "walk_comfort_score"
    }
}
