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
        } catch {
            appendAssistantMessage("I hit a connection issue while checking the latest weather context. Please try again.")
        }

        isSending = false
    }
}
