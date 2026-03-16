import SwiftUI

struct ContentView: View {
    @StateObject private var weatherSnapshotStore: WeatherSnapshotStore
    @StateObject private var chatViewModel: ChatViewModel

    init() {
        let store = WeatherSnapshotStore()
        _weatherSnapshotStore = StateObject(wrappedValue: store)
        _chatViewModel = StateObject(
            wrappedValue: ChatViewModel(
                chatService: SupabaseChatService(),
                weatherSnapshotStore: store
            )
        )
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            ChatView(viewModel: chatViewModel)
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .environmentObject(weatherSnapshotStore)
    }
}

#Preview {
    ContentView()
}
