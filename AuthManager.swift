import Foundation
import SwiftUI
import AuthenticationServices
import UIKit
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@MainActor
final class AuthManager: NSObject, ObservableObject, AuthTokenProviding {
    @Published private(set) var session: AuthSession?
    @Published private(set) var isRestoringSession = true
    @Published var authErrorMessage: String?
    @Published var authInfoMessage: String?

    private let storageKey = "judy.auth.session"
    private var webSession: ASWebAuthenticationSession?

    var isAuthenticated: Bool {
        session != nil
    }

    override init() {
        super.init()
        Task {
            await restoreSessionIfPossible()
        }
    }

    func currentAccessToken() async -> String? {
        let hasSession = session != nil
        let isExpired = session?.isExpired ?? true
        let expiresSoon = session?.expiresSoon ?? true
        print("[Auth] Access token request - has session: \(hasSession), expired: \(isExpired), expiresSoon: \(expiresSoon)")

        if expiresSoon {
            do {
                try await refreshSessionIfNeeded(force: true)
            } catch {
                print("[Auth] Token refresh failed before chat request")
                if isExpired {
                    return nil
                }
            }
        }

        let token = session?.accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let tokenPresent = !(token?.isEmpty ?? true)
        print("[Auth] Access token present for chat: \(tokenPresent)")

        guard let token, !token.isEmpty else {
            return nil
        }

        return token
    }

    func restoreSessionIfPossible() async {
        defer { isRestoringSession = false }

        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            print("[Auth] No stored session found")
            return
        }

        do {
            let decoded = try JSONDecoder().decode(AuthSession.self, from: data)
            session = decoded
            print("[Auth] Restored session for user id: \(decoded.user.id)")
            try await refreshSessionIfNeeded(force: decoded.isExpired || decoded.expiresSoon)
        } catch {
            print("[Auth] Failed to decode stored session")
            clearSession()
        }
    }

    func signIn(email: String, password: String) async {
        authErrorMessage = nil
        authInfoMessage = nil

        do {
            let response = try await requestAuth(
                path: "/auth/v1/token?grant_type=password",
                body: [
                    "email": email,
                    "password": password,
                ]
            )

            guard let newSession = response.toSession() else {
                throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sign in succeeded without a usable session."])
            }

            setSession(newSession)
        } catch {
            authErrorMessage = error.localizedDescription
        }
    }

    func signUp(email: String, password: String) async {
        authErrorMessage = nil
        authInfoMessage = nil

        do {
            let response = try await requestAuth(
                path: "/auth/v1/signup",
                body: [
                    "email": email,
                    "password": password,
                ]
            )

            if let newSession = response.toSession() {
                setSession(newSession)
                authInfoMessage = "Account created and signed in."
            } else {
                authInfoMessage = "Account created. Check your email to verify, then sign in."
            }
        } catch {
            authErrorMessage = error.localizedDescription
        }
    }

    func signInWithProvider(_ provider: OAuthProvider) async {
        authErrorMessage = nil
        authInfoMessage = nil

        do {
            let callbackURL = try await startOAuth(provider: provider)
            let authResponse = try parseOAuthCallback(callbackURL)

            if let newSession = authResponse.toSession() {
                setSession(newSession)
                return
            }

            throw NSError(
                domain: "Auth",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "OAuth completed but no session token was returned."]
            )
        } catch {
            authErrorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        authErrorMessage = nil
        authInfoMessage = nil

        guard let session else {
            clearSession()
            return
        }

        do {
            _ = try await requestRaw(
                path: "/auth/v1/logout",
                method: "POST",
                bearer: session.accessToken,
                bodyData: nil
            )
        } catch {
            print("[Auth] Logout request failed; clearing local session anyway")
        }

        clearSession()
    }

    func validateEmailAndPassword(email: String, password: String) -> String? {
        guard email.contains("@"), email.contains(".") else {
            return "Please enter a valid email address."
        }

        guard password.count >= 6 else {
            return "Password must be at least 6 characters."
        }

        return nil
    }

    private func refreshSessionIfNeeded(force: Bool) async throws {
        guard force, let refreshToken = session?.refreshToken else { return }

        let response = try await requestAuth(
            path: "/auth/v1/token?grant_type=refresh_token",
            body: ["refresh_token": refreshToken]
        )

        guard let updated = response.toSession() else {
            throw NSError(domain: "Auth", code: -3, userInfo: [NSLocalizedDescriptionKey: "Could not refresh auth session."])
        }

        setSession(updated)
    }

    private func requestAuth(path: String, body: [String: String]) async throws -> AuthResponse {
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let (data, httpResponse) = try await requestRaw(
            path: path,
            method: "POST",
            bearer: nil,
            bodyData: bodyData
        )

        guard 200..<300 ~= httpResponse.statusCode else {
            let backend = try? JSONDecoder().decode(AuthErrorResponse.self, from: data)
            let message = backend?.bestMessage ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw NSError(domain: "Auth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }

        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    private func requestRaw(path: String, method: String, bearer: String?, bodyData: Data?) async throws -> (Data, HTTPURLResponse) {
        let baseURL = Config.supabaseProjectURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let anonKey = Config.supabaseAnonKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !baseURL.isEmpty, !anonKey.isEmpty,
              let url = URL(string: "\(baseURL)\(path)") else {
            throw NSError(domain: "Auth", code: -4, userInfo: [NSLocalizedDescriptionKey: "Supabase auth configuration is missing."])
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        if let bearer {
            request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = bodyData

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        return (data, httpResponse)
    }

    private func startOAuth(provider: OAuthProvider) async throws -> URL {
        let baseURL = Config.supabaseProjectURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let redirectURL = "\(Config.oauthRedirectScheme)://auth-callback"

        guard !baseURL.isEmpty else {
            throw NSError(domain: "Auth", code: -5, userInfo: [NSLocalizedDescriptionKey: "Supabase project URL is missing."])
        }

        var components = URLComponents(string: "\(baseURL)/auth/v1/authorize")
        components?.queryItems = [
            URLQueryItem(name: "provider", value: provider.rawValue),
            URLQueryItem(name: "redirect_to", value: redirectURL),
            URLQueryItem(name: "scope", value: "openid email profile"),
        ]

        guard let authorizeURL = components?.url else {
            throw NSError(domain: "Auth", code: -6, userInfo: [NSLocalizedDescriptionKey: "Could not create OAuth URL."])
        }

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authorizeURL,
                callbackURLScheme: Config.oauthRedirectScheme
            ) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let callbackURL else {
                    continuation.resume(throwing: NSError(domain: "Auth", code: -7, userInfo: [NSLocalizedDescriptionKey: "No OAuth callback URL was received."]))
                    return
                }

                continuation.resume(returning: callbackURL)
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.webSession = session
            session.start()
        }
    }

    private func parseOAuthCallback(_ callbackURL: URL) throws -> AuthResponse {
        let params = parseQueryAndFragment(from: callbackURL)

        if let errorDescription = params["error_description"] ?? params["error"] {
            throw NSError(domain: "Auth", code: -8, userInfo: [NSLocalizedDescriptionKey: errorDescription])
        }

        let accessToken = params["access_token"]
        let refreshToken = params["refresh_token"]
        let expiresIn = params["expires_in"].flatMap(Int.init)
        let expiresAt = params["expires_at"].flatMap(Double.init)
        let userID = accessToken.flatMap(extractSubjectFromJWT) ?? params["provider_id"] ?? "oauth-user"

        let user = AuthUser(
            id: userID,
            email: params["email"]
        )

        return AuthResponse(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn,
            expiresAtEpoch: expiresAt,
            user: (accessToken != nil && refreshToken != nil) ? user : nil,
            errorDescription: nil
        )
    }

    private func parseQueryAndFragment(from url: URL) -> [String: String] {
        var output: [String: String] = [:]

        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            for item in queryItems {
                output[item.name] = item.value
            }
        }

        if let fragment = URLComponents(url: url, resolvingAgainstBaseURL: false)?.fragment {
            for part in fragment.split(separator: "&") {
                let pieces = part.split(separator: "=", maxSplits: 1)
                guard let key = pieces.first else { continue }
                let value = pieces.count > 1 ? String(pieces[1]) : ""
                output[String(key)] = value.removingPercentEncoding ?? value
            }
        }

        return output
    }

    private func extractSubjectFromJWT(_ token: String) -> String? {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }

        var payload = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let remainder = payload.count % 4
        if remainder > 0 {
            payload += String(repeating: "=", count: 4 - remainder)
        }

        guard let data = Data(base64Encoded: payload),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sub = object["sub"] as? String,
              !sub.isEmpty else {
            return nil
        }

        return sub
    }

    private func setSession(_ newSession: AuthSession) {
        session = newSession

        if let encoded = try? JSONEncoder().encode(newSession) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }

        print("[Auth] Authenticated session active for user id: \(newSession.user.id)")
    }

    private func clearSession() {
        session = nil
        UserDefaults.standard.removeObject(forKey: storageKey)
        print("[Auth] Session cleared")
    }
}

extension AuthManager: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            return window
        }
        return ASPresentationAnchor()
    }
}

enum OAuthProvider: String {
    case apple
    case google
}
