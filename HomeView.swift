import SwiftUI
import CoreLocation

struct HomeView: View {
    @State private var weatherContext: WeatherContextResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?

    @EnvironmentObject private var weatherSnapshotStore: WeatherSnapshotStore

    private let weatherService = WeatherService()
    private let locationService = LocationService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView("Loading weather...")
                } else if let weatherContext = weatherContext {
                    let snapshot = weatherContext.weatherSnapshot
                    let adviceText = homeSummary(from: weatherContext)
                    let apparentTemperature = Int(snapshot.feelsLike.rounded())

                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 60))

                    Text("Current Location")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("\(Int(snapshot.temperature.rounded()))°C")
                        .font(.system(size: 48, weight: .bold))

                    Text("Feels like \(apparentTemperature)°C")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Text(snapshot.condition.capitalized)
                        .font(.headline)

                    Text("Wind: \(snapshot.windSpeed, specifier: "%.1f") m/s")
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
            let coordinate = try await locationService.requestCurrentLocation()
            let fetchedWeatherContext = try await weatherService.fetchWeatherContext(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            weatherContext = fetchedWeatherContext
            weatherSnapshotStore.update(with: fetchedWeatherContext.weatherSnapshot)
        } catch {
            errorMessage = error.localizedDescription
            weatherContext = nil
            weatherSnapshotStore.clear()
        }

        isLoading = false
    }

    private func homeSummary(from context: WeatherContextResponse) -> String {
        var points: [String] = []

        if context.derivedFlags.umbrellaNeeded {
            points.append("Take an umbrella")
        }

        if context.derivedFlags.strongWindWarning {
            points.append("expect strong wind")
        }

        if context.derivedFlags.lightJacketRecommended {
            points.append("a light jacket is recommended")
        }

        if points.isEmpty {
            points.append("Conditions look fairly comfortable")
        }

        return "\(points.joined(separator: ", ")). Walk comfort: \(context.derivedFlags.walkComfortScore)/100."
    }
}

private final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var authorizationContinuation: CheckedContinuation<Void, Error>?
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    @MainActor
    func requestCurrentLocation() async throws -> CLLocationCoordinate2D {
        guard CLLocationManager.locationServicesEnabled() else {
            throw LocationError.servicesDisabled
        }

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            break
        case .notDetermined:
            try await requestAuthorization()
        case .denied, .restricted:
            throw LocationError.permissionDenied
        @unknown default:
            throw LocationError.permissionDenied
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            self.manager.requestLocation()
        }
    }

    @MainActor
    private func requestAuthorization() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.authorizationContinuation = continuation
            self.manager.requestWhenInUseAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let continuation = authorizationContinuation else { return }

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            authorizationContinuation = nil
            continuation.resume()
        case .denied, .restricted:
            authorizationContinuation = nil
            continuation.resume(throwing: LocationError.permissionDenied)
        case .notDetermined:
            break
        @unknown default:
            authorizationContinuation = nil
            continuation.resume(throwing: LocationError.permissionDenied)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.first?.coordinate,
              let continuation = locationContinuation else { return }
        locationContinuation = nil
        continuation.resume(returning: coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard let continuation = locationContinuation else { return }
        locationContinuation = nil
        continuation.resume(throwing: error)
    }
}

private enum LocationError: LocalizedError {
    case servicesDisabled
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .servicesDisabled:
            return "Location services are disabled. Please enable them to load local weather."
        case .permissionDenied:
            return "Location permission is needed to fetch weather for your current position."
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(WeatherSnapshotStore())
}
