import Foundation
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var draftMessage: String = ""
    @Published var isSending = false

    private let chatService: ChatServicing
    private let weatherSnapshotStore: WeatherSnapshotStore

    init(chatService: ChatServicing, weatherSnapshotStore: WeatherSnapshotStore) {
        self.chatService = chatService
        self.weatherSnapshotStore = weatherSnapshotStore
    }

    func sendCurrentDraft() {
        let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }

        draftMessage = ""
        appendUserMessage(trimmed)

        Task {
            await fetchAssistantReply(for: trimmed)
        }
    }

    private func appendUserMessage(_ text: String) {
        messages.append(ChatMessage(role: .user, text: text))
    }

    private func appendAssistantMessage(_ text: String) {
        messages.append(ChatMessage(role: .assistant, text: text))
    }

    private func fetchAssistantReply(for userText: String) async {
        guard let snapshot = weatherSnapshotStore.snapshot else {
            appendAssistantMessage("I need current weather data first. Open Home once so I can answer accurately.")
            return
        }

        isSending = true

        let recentMessages = messages
            .suffix(6)
            .map { JudyRecentMessage(role: $0.role, text: $0.text) }

        let request = JudyChatRequest(
            modality: "text",
            userMessage: userText,
            weatherSnapshot: snapshot,
            recentMessages: recentMessages
        )

        do {
            let reply = try await chatService.sendChat(request: request)
            appendAssistantMessage(reply)
        } catch let chatError as ChatServiceError {
            appendAssistantMessage(message(for: chatError))
        } catch {
            appendAssistantMessage("I hit a connection issue while checking the latest weather context. Please try again.")
        }

        isSending = false
    }

    private func message(for error: ChatServiceError) -> String {
        switch error {
        case .missingConfiguration:
            return "I can’t chat yet because Supabase settings are missing in the app configuration."
        case .invalidURL:
            return "I can’t reach the chat backend because the server URL is invalid."
        case .unauthorized:
            return "I can’t reach chat right now due to an authorization issue with Supabase."
        case .server(let statusCode, let message):
            if let message, message.localizedCaseInsensitiveContains("OPENAI_API_KEY") {
                return "Chat backend is online, but OPENAI_API_KEY is not configured in Supabase Edge Function secrets."
            }

            return "The chat backend returned an error (\(statusCode)). Please check Supabase function logs and try again."
        }
    }
}
