import Foundation
import SwiftUI
import Combine

@MainActor
final class UserSession: ObservableObject {
    init() {}

    @Published var user: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = true

    private let refreshTokenKey = "refreshToken"
    private let keychainService = "GPTToolkitMacApp"

    private(set) var accessToken: String?

    var apiClient: APIClient {
        APIClient(baseURL: APIConfig.baseURL, accessToken: accessToken)
    }

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {
        do {
            return try await apiClient.request(path, method: method, body: body)
        } catch let APIClient.APIError.server(statusCode, _) where statusCode == 401 {
            do {
                try await refresh()
                return try await apiClient.request(path, method: method, body: body)
            } catch {
                clearSession()
                throw error
            }
        }
    }

    func loadCurrentUser() async {
        defer { isLoading = false }
        guard refreshToken != nil else {
            isAuthenticated = false
            return
        }

        if accessToken == nil {
            do {
                try await refresh()
            } catch {
                clearSession()
                return
            }
        }

        do {
            let response: UserResponse = try await request("auth/me")
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

    func logout() async {
        if let refreshToken {
            let body = LogoutRequest(refreshToken: refreshToken)
            if let data = try? JSONEncoder().encode(body) {
                _ = try? await apiClient.request("auth/logout", method: "POST", body: data) as APIClient.EmptyResponse
            }
        }
        clearSession()
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

    private func clearSession() {
        accessToken = nil
        KeychainStore.shared.delete(service: keychainService, account: refreshTokenKey)
        user = nil
        isAuthenticated = false
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

struct LogoutRequest: Codable {
    let refreshToken: String
}
