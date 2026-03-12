import Foundation
#if canImport(ObjectiveC)
import ObjectiveC
#endif

enum Config {
    static var openWeatherAPIKey: String {
        if let localKey = localConfigAPIKey, !localKey.isEmpty {
            return localKey
        }

        if let environmentKey = ProcessInfo.processInfo.environment["OPENWEATHER_API_KEY"],
           !environmentKey.isEmpty {
            return environmentKey
        }

        return "YOUR_OPENWEATHER_API_KEY"
    }

    private static var localConfigAPIKey: String? {
        #if canImport(ObjectiveC)
        guard let localConfigClass = NSClassFromString("LocalConfig") as? NSObject.Type,
              localConfigClass.responds(to: NSSelectorFromString("openWeatherAPIKey")),
              let value = localConfigClass.perform(NSSelectorFromString("openWeatherAPIKey"))?
                .takeUnretainedValue() as? String else {
            return nil
        }

        return value
        #else
        return nil
        #endif
    }
}
