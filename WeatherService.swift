import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class WeatherService {
    func fetchWeatherContext(latitude: Double, longitude: Double) async throws -> WeatherContextResponse {
        let baseURL = Config.supabaseProjectURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let anonKey = Config.supabaseAnonKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !baseURL.isEmpty, !anonKey.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }

        guard let url = URL(string: "\(baseURL)/functions/v1/weather-context") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        let payload: [String: Double] = [
            "latitude": latitude,
            "longitude": longitude,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(WeatherContextResponse.self, from: data)
    }
}
