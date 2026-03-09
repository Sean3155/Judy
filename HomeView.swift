import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 60))
                
                Text("Judy Home")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Weather guidance will appear here.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView()
}
