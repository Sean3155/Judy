import Foundation

enum Config {
    static var supabaseProjectURL: String {
        configValue(
            environmentKey: "SUPABASE_PROJECT_URL",
            fallback: "YOUR_SUPABASE_PROJECT_URL"
        )
    }

    static var supabaseAnonKey: String {
        configValue(
            environmentKey: "SUPABASE_ANON_KEY",
            fallback: "YOUR_SUPABASE_ANON_KEY"
        )
    }

    private static func configValue(
        environmentKey: String,
        fallback: String
    ) -> String {
        if let environmentValue = ProcessInfo.processInfo.environment[environmentKey],
           !environmentValue.isEmpty {
            return environmentValue
        }

        return fallback
    }
}
