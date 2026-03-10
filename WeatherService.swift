import Foundation

final class WeatherService {
    func fetchWeather(for city: String) async throws -> WeatherResponse {
        let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(encodedCity)&appid=\(Config.openWeatherAPIKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(WeatherResponse.self, from: data)
    }
}
