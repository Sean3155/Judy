import Foundation
import Combine

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

@MainActor
final class WeatherSnapshotStore: ObservableObject {
    @Published private(set) var snapshot: ChatWeatherSnapshot?

    func update(with weather: WeatherResponse, advice: WeatherAdvice) {
        snapshot = ChatWeatherSnapshot(
            temperature: weather.main.temp,
            feelsLike: advice.apparentTemperatureC,
            humidity: weather.main.humidity,
            windSpeed: weather.wind.speed,
            windGust: weather.wind.gust ?? weather.wind.speed,
            precipitationProbability: estimatePrecipitationProbability(from: advice.rainImpact),
            condition: weather.weather.first?.description.lowercased() ?? "",
            visibility: 0
        )
    }

    func clear() {
        snapshot = nil
    }

    private func estimatePrecipitationProbability(from rainImpact: RainImpactLevel) -> Double {
        switch rainImpact {
        case .none:
            return 0.05
        case .light:
            return 0.30
        case .moderate:
            return 0.60
        case .heavy:
            return 0.85
        }
    }
}
