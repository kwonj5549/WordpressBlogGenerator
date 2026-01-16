import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let wpAuthStatus: Bool?

    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case wpAuthStatus
        case wpAuthStatusUpper = "WPAuthStatus"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decode(String.self, forKey: .name)
        wpAuthStatus = try container.decodeIfPresent(Bool.self, forKey: .wpAuthStatus)
            ?? container.decodeIfPresent(Bool.self, forKey: .wpAuthStatusUpper)
    }
}
