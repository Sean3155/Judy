import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct JudyRecentMessage: Codable {
    let role: ChatRole
    let text: String
}

struct JudyChatRequest: Codable {
    let modality: String
    let userMessage: String
    let weatherSnapshot: ChatWeatherSnapshot
    let recentMessages: [JudyRecentMessage]

    enum CodingKeys: String, CodingKey {
        case modality
        case userMessage = "user_message"
        case weatherSnapshot = "weather_snapshot"
        case recentMessages = "recent_messages"
    }
}

private struct JudyChatResponse: Decodable {
    let reply: String
}

protocol ChatServicing {
    func sendChat(request: JudyChatRequest) async throws -> String
}

final class SupabaseChatService: ChatServicing {
    func sendChat(request: JudyChatRequest) async throws -> String {
        let baseURL = Config.supabaseProjectURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let anonKey = Config.supabaseAnonKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !baseURL.isEmpty, !anonKey.isEmpty,
              !baseURL.contains("YOUR_SUPABASE") else {
            throw URLError(.userAuthenticationRequired)
        }

        guard let url = URL(string: "\(baseURL)/functions/v1/chat") else {
            throw URLError(.badURL)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(anonKey, forHTTPHeaderField: "apikey")
        urlRequest.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(JudyChatResponse.self, from: data)
        return decoded.reply
    }
}
