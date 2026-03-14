import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }

                            if viewModel.isSending {
                                HStack {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Judy is thinking...")
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isInputFocused = false
                    }
                    .onChange(of: viewModel.messages.count) {
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: viewModel.isSending) {
                        scrollToBottom(proxy: proxy)
                    }

                    ChatInputBar(
                        text: $viewModel.draftMessage,
                        isFocused: $isInputFocused,
                        isSending: viewModel.isSending,
                        onSend: {
                            isInputFocused = false
                            viewModel.sendCurrentDraft()
                        }
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Chat")
            .background(Color(.systemBackground))
            .onDisappear {
                isInputFocused = false
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastID = viewModel.messages.last?.id else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(lastID, anchor: .bottom)
        }
    }
}

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .assistant {
                bubble
                Spacer(minLength: 48)
            } else {
                Spacer(minLength: 48)
                bubble
            }
        }
        .padding(.horizontal)
    }

    private var bubble: some View {
        Text(message.text)
            .foregroundStyle(message.role == .assistant ? .primary : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(message.role == .assistant ? Color(.secondarySystemBackground) : Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ChatInputBar: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let isSending: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("Ask Judy about the weather…", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .focused($isFocused)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
    }
}

#Preview {
    ChatView(viewModel: ChatViewModel(chatService: SupabaseChatService(), weatherSnapshotStore: WeatherSnapshotStore()))
}
