import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let wpAuthStatus: Bool?
}
