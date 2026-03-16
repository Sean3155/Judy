import Foundation

protocol AuthTokenProviding: AnyObject {
    func currentAccessToken() async -> String?
}
