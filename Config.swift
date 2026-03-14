import Foundation
#if canImport(ObjectiveC)
import ObjectiveC
#endif

enum Config {
    static var openWeatherAPIKey: String {
        configValue(
            localSelector: "openWeatherAPIKey",
            environmentKey: "OPENWEATHER_API_KEY",
            fallback: "YOUR_OPENWEATHER_API_KEY"
        )
    }

    static var supabaseProjectURL: String {
        configValue(
            localSelector: "supabaseProjectURL",
            environmentKey: "SUPABASE_PROJECT_URL",
            fallback: "YOUR_SUPABASE_PROJECT_URL"
        )
    }

    static var supabaseAnonKey: String {
        configValue(
            localSelector: "supabaseAnonKey",
            environmentKey: "SUPABASE_ANON_KEY",
            fallback: "YOUR_SUPABASE_ANON_KEY"
        )
    }

    private static func configValue(
        localSelector: String,
        environmentKey: String,
        fallback: String
    ) -> String {
        if let local = localConfigValue(for: localSelector), !local.isEmpty {
            return local
        }

        if let environmentValue = ProcessInfo.processInfo.environment[environmentKey],
           !environmentValue.isEmpty {
            return environmentValue
        }

        return fallback
    }

    private static func localConfigValue(for selector: String) -> String? {
        #if canImport(ObjectiveC)
        guard let localConfigClass = NSClassFromString("LocalConfig") as? NSObject.Type,
              localConfigClass.responds(to: NSSelectorFromString(selector)),
              let value = localConfigClass.perform(NSSelectorFromString(selector))?.takeUnretainedValue() as? String else {
            return nil
        }

        return value
        #else
        return nil
        #endif
    }
}
