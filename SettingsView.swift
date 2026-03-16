import SwiftUI

struct SettingsView: View {
    @ObservedObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    if let session = authManager.session {
                        Text(session.user.email ?? "Signed in")
                            .foregroundStyle(.secondary)

                        Button(role: .destructive) {
                            Task { await authManager.signOut() }
                        } label: {
                            Text("Sign Out")
                        }
                    } else {
                        Text("Not signed in")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView(authManager: AuthManager())
}
