import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 60))
                
                Text("Judy Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("App settings will appear here.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
