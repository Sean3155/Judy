import Foundation
#if canImport(ObjectiveC)
import ObjectiveC
#endif

enum Config {
    static var supabaseProjectURL: String {
        configValue(
            infoPlistKey: "SUPABASE_PROJECT_URL",
            environmentKey: "SUPABASE_PROJECT_URL",
            fallback: ""
        )
    }

    static var supabaseAnonKey: String {
        configValue(
            infoPlistKey: "SUPABASE_ANON_KEY",
            environmentKey: "SUPABASE_ANON_KEY",
            fallback: ""
        )
    }

    static var oauthRedirectScheme: String {
        configValue(
            infoPlistKey: "OAUTH_REDIRECT_SCHEME",
            environmentKey: "OAUTH_REDIRECT_SCHEME",
            fallback: "judy"
        )
    }

    private static func configValue(
        infoPlistKey: String,
        environmentKey: String,
        fallback: String
    ) -> String {
        if let plistValue = Bundle.main.object(forInfoDictionaryKey: infoPlistKey) as? String,
           !plistValue.isEmpty {
            return plistValue
        }

        if let environmentValue = ProcessInfo.processInfo.environment[environmentKey],
           !environmentValue.isEmpty {
            return environmentValue
        }

        return fallback
    }
}
