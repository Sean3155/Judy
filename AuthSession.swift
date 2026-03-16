import Foundation

struct AuthUser: Codable {
    let id: String
    let email: String?
}

struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let user: AuthUser

    var isExpired: Bool {
        expiresAt <= Date()
    }

    var expiresSoon: Bool {
        expiresAt.timeIntervalSinceNow < 90
    }
}

struct AuthResponse: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let expiresIn: Int?
    let expiresAtEpoch: Double?
    let user: AuthUser?
    let errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case expiresAtEpoch = "expires_at"
        case user
        case errorDescription = "error_description"
    }

    func toSession() -> AuthSession? {
        guard let accessToken,
              let refreshToken,
              let user else {
            return nil
        }

        let expiration: Date
        if let expiresAtEpoch {
            expiration = Date(timeIntervalSince1970: expiresAtEpoch)
        } else if let expiresIn {
            expiration = Date().addingTimeInterval(TimeInterval(expiresIn))
        } else {
            expiration = Date().addingTimeInterval(3600)
        }

        return AuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiration,
            user: user
        )
    }
}

struct AuthErrorResponse: Decodable {
    let error: String?
    let errorDescription: String?
    let msg: String?

    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case msg
    }

    var bestMessage: String {
        errorDescription ?? msg ?? error ?? "Authentication failed."
    }
}
