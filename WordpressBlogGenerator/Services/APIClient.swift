import Foundation

struct APIClient {
    struct EmptyResponse: Decodable {}

    enum APIError: LocalizedError {
        case invalidResponse
        case server(statusCode: Int, message: String)
        case decoding

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid server response."
            case .server(_, let message):
                return message
            case .decoding:
                return "Unable to read server response."
            }
        }
    }

    var baseURL: URL
    var accessToken: String?

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.httpBody = body
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let statusCode = httpResponse.statusCode
            let message = parseErrorMessage(from: data) ?? "Request failed with status code \(statusCode)."
            throw APIError.server(statusCode: statusCode, message: message)
        }

        if data.isEmpty {
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            throw APIError.decoding
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    private func parseErrorMessage(from data: Data) -> String? {
        let decoder = JSONDecoder()
        if let response = try? decoder.decode(ErrorMessageResponse.self, from: data) {
            if let message = response.message {
                return message
            }
            if let detail = response.errors?.first?.detail {
                return detail
            }
            if let errorDict = response.errorsDict?.values.first?.first {
                return errorDict
            }
        }
        return nil
    }
}

struct ErrorMessageResponse: Decodable {
    let message: String?
    let errors: [ErrorDetail]?
    let errorsDict: [String: [String]]?

    private enum CodingKeys: String, CodingKey {
        case message
        case errors
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        errors = try? container.decode([ErrorDetail].self, forKey: .errors)
        errorsDict = try? container.decode([String: [String]].self, forKey: .errors)
    }
}

struct ErrorDetail: Decodable {
    let detail: String
}
