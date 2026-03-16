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

private struct JudyErrorResponse: Decodable {
    let error: String
}

enum ChatServiceError: LocalizedError {
    case missingConfiguration
    case invalidURL
    case unauthorized(message: String?)
    case server(statusCode: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Supabase chat configuration is missing."
        case .invalidURL:
            return "Supabase chat URL is invalid."
        case .unauthorized(let message):
            return message ?? "Chat request was not authorized."
        case .server(_, let message):
            return message ?? "Chat backend returned an error."
        }
    }
}

protocol ChatServicing {
    func sendChat(request: JudyChatRequest) async throws -> String
}

final class SupabaseChatService: ChatServicing {
    private weak var authTokenProvider: AuthTokenProviding?

    init(authTokenProvider: AuthTokenProviding? = nil) {
        self.authTokenProvider = authTokenProvider
    }

    func sendChat(request: JudyChatRequest) async throws -> String {
        let baseURL = Config.supabaseProjectURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let anonKey = Config.supabaseAnonKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !baseURL.isEmpty, !anonKey.isEmpty else {
            throw ChatServiceError.missingConfiguration
        }

        guard let url = URL(string: "\(baseURL)/functions/v1/chat") else {
            throw ChatServiceError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(anonKey, forHTTPHeaderField: "apikey")

        let accessToken = await authTokenProvider?.currentAccessToken()
        let bearerToken = accessToken ?? anonKey
        let hasAuthenticatedContext = accessToken != nil
        print("[Auth] Chat request uses authenticated context: \(hasAuthenticatedContext)")
        urlRequest.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let backendError = try? JSONDecoder().decode(JudyErrorResponse.self, from: data)
            let message = backendError?.error

            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw ChatServiceError.unauthorized(message: message)
            }

            throw ChatServiceError.server(statusCode: httpResponse.statusCode, message: message)
        }

        let decoded = try JSONDecoder().decode(JudyChatResponse.self, from: data)
        return decoded.reply
    }
}
