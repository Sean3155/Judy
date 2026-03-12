import SwiftUI

struct HomeView: View {
    @State private var weather: WeatherResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let weatherService = WeatherService()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView("Loading weather...")
                } else if let weather = weather {
                    let advice = WeatherAdviceEngine.generateAdvice(from: weather)
                    let adviceText = AdviceFormatter.homeCardText(from: advice)
                    
                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 60))
                    
                    Text(weather.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("\(Int(weather.main.temp))°C")
                        .font(.system(size: 48, weight: .bold))
                    
                    Text("Feels like \(Int(weather.main.feelsLike))°C")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    Text(weather.weather.first?.description.capitalized ?? "No description")
                        .font(.headline)
                    
                    Text("Wind: \(weather.wind.speed, specifier: "%.1f") m/s")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    Text(adviceText)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .padding(.horizontal)
                } else if let errorMessage = errorMessage {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                    
                    Text("Could not load weather")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                } else {
                    Text("No weather data yet")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .navigationTitle("Home")
            .task {
                await loadWeather()
            }
        }
    }
    
    @MainActor
    private func loadWeather() async {
        isLoading = true
        errorMessage = nil
        
        do {
            weather = try await weatherService.fetchWeather(for: "Madison")
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

#Preview {
    HomeView()
}
