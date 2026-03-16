import SwiftUI

struct ContentView: View {
    @ObservedObject var authManager: AuthManager

    @StateObject private var weatherSnapshotStore: WeatherSnapshotStore
    @StateObject private var chatViewModel: ChatViewModel

    init(authManager: AuthManager) {
        self.authManager = authManager

        let store = WeatherSnapshotStore()
        _weatherSnapshotStore = StateObject(wrappedValue: store)
        _chatViewModel = StateObject(
            wrappedValue: ChatViewModel(
                chatService: SupabaseChatService(authTokenProvider: authManager),
                weatherSnapshotStore: store
            )
        )
    }

    var body: some View {
        Group {
            if authManager.isRestoringSession {
                ProgressView("Restoring session...")
            } else if authManager.isAuthenticated {
                TabView {
                    HomeView()
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }

                    ChatView(viewModel: chatViewModel)
                        .tabItem {
                            Label("Chat", systemImage: "message.fill")
                        }

                    SettingsView(authManager: authManager)
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                }
                .environmentObject(weatherSnapshotStore)
            } else {
                AuthView(authManager: authManager)
            }
        }
    }
}

#Preview {
    ContentView(authManager: AuthManager())
}
