import Foundation
import Combine

@MainActor
final class WeatherSnapshotStore: ObservableObject {
    @Published private(set) var snapshot: ChatWeatherSnapshot?

    func update(with snapshot: ChatWeatherSnapshot) {
        self.snapshot = snapshot
    }

    func clear() {
        snapshot = nil
    }
}
