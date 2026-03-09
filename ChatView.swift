import SwiftUI

struct ChatView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "message.fill")
                    .font(.system(size: 60))
                
                Text("Judy Chat")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Conversation with Judy will happen here.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Chat")
        }
    }
}

#Preview {
    ChatView()
}
