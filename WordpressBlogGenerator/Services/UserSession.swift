import Foundation
import SwiftUI
import Combine

@MainActor
final class UserSession: ObservableObject {
    init() {}

    @Published var user: User?
    @Published var isAuthenticated: Bool = false

    private let refreshTokenKey = "refreshToken"
    private let keychainService = "GPTToolkitMacApp"

    private(set) var accessToken: String?

    var apiClient: APIClient {
        APIClient(baseURL: URL(string: "https://api.example.com")!, accessToken: accessToken)
    }

    func loadCurrentUser() async {
        guard accessToken != nil || refreshToken != nil else {
            isAuthenticated = false
            return
        }

        do {
            let response: UserResponse = try await apiClient.request("auth/me")
            user = response.user
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
    }

    func login(email: String, password: String) async throws {
        let body = LoginRequest(email: email, password: password)
        let data = try JSONEncoder().encode(body)
        let response: AuthResponse = try await apiClient.request("auth/login", method: "POST", body: data)
        handleAuthResponse(response)
    }

    func register(name: String, email: String, password: String) async throws {
        let body = RegisterRequest(name: name, email: email, password: password)
        let data = try JSONEncoder().encode(body)
        let response: AuthResponse = try await apiClient.request("auth/register", method: "POST", body: data)
        handleAuthResponse(response)
    }

    func logout() {
        accessToken = nil
        KeychainStore.shared.delete(service: keychainService, account: refreshTokenKey)
        user = nil
        isAuthenticated = false
    }

    func refresh() async throws {
        guard let refreshToken else { return }
        let body = RefreshRequest(refreshToken: refreshToken)
        let data = try JSONEncoder().encode(body)
        let response: RefreshResponse = try await apiClient.request("auth/refresh", method: "POST", body: data)
        accessToken = response.accessToken
        saveRefreshToken(response.refreshToken)
    }

    private func handleAuthResponse(_ response: AuthResponse) {
        user = response.user
        accessToken = response.accessToken
        saveRefreshToken(response.refreshToken)
        isAuthenticated = true
    }

    private var refreshToken: String? {
        guard let data = KeychainStore.shared.read(service: keychainService, account: refreshTokenKey) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func saveRefreshToken(_ token: String) {
        if let data = token.data(using: .utf8) {
            KeychainStore.shared.save(data, service: keychainService, account: refreshTokenKey)
        }
    }
}

struct AuthResponse: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String
}

struct RefreshResponse: Codable {
    let accessToken: String
    let refreshToken: String
}

struct UserResponse: Codable {
    let user: User
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let name: String
    let email: String
    let password: String
}

struct RefreshRequest: Codable {
    let refreshToken: String
}
