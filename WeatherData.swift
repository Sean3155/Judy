import Foundation

struct WeatherResponse: Decodable {
    let name: String
    let weather: [WeatherInfo]
    let main: MainInfo
    let wind: WindInfo
}

struct WeatherInfo: Decodable {
    let main: String
    let description: String
}

struct MainInfo: Decodable {
    let temp: Double
    let feelsLike: Double

    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
    }
}

struct WindInfo: Decodable {
    let speed: Double
}
