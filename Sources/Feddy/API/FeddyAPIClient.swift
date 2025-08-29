import Foundation

public enum FeddyAPIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case serverError(String)
    case invalidAPIKey
    case rateLimited
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .invalidAPIKey:
            return "Invalid API key"
        case .rateLimited:
            return "Rate limit exceeded"
        }
    }
}

public final class FeddyAPIClient: Sendable {
    public let apiKey: String
    private let baseURL: String
    private let session: URLSession
    
    public init(apiKey: String, baseURL: String = "https://feddy.app") {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.session = URLSession.shared
    }
    
    // MARK: - Public API Methods
    
    public func getFeedbacks(
        status: FeedbackStatus? = nil,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> FeedbackListResponse {
        var components = URLComponents(string: baseURL + APIEndpoints.getFeedbacks)!
        var queryItems: [URLQueryItem] = []
        
        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status.rawValue))
        }
        if limit != 50 {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if offset > 0 {
            queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        }
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else {
            throw FeddyAPIError.invalidURL
        }
        
        let response: APIResponse<FeedbackListResponse> = try await performRequest(
            url: url,
            method: .GET
        )
        
        guard let data = response.data else {
            throw FeddyAPIError.serverError(response.error ?? "Unknown error")
        }
        
        return data
    }
    
    public func submitFeedback(_ submission: FeedbackSubmission) async throws -> FeedbackSubmissionResponse {
        guard let url = URL(string: baseURL + APIEndpoints.submitFeedback) else {
            throw FeddyAPIError.invalidURL
        }
        
        let response: APIResponse<FeedbackSubmissionResponse> = try await performRequest(
            url: url,
            method: .POST,
            body: submission
        )
        
        guard let data = response.data else {
            throw FeddyAPIError.serverError(response.error ?? "Unknown error")
        }
        
        return data
    }
    
    public func voteFeedback(_ vote: VoteRequest) async throws -> VoteResponse {
        guard let url = URL(string: baseURL + APIEndpoints.voteFeedback) else {
            throw FeddyAPIError.invalidURL
        }
        
        let response: APIResponse<VoteResponse> = try await performRequest(
            url: url,
            method: .POST,
            body: vote
        )
        
        guard let data = response.data else {
            throw FeddyAPIError.serverError(response.error ?? "Unknown error")
        }
        
        return data
    }
    
    // MARK: - Private Methods
    
    private func performRequest<T: Codable>(
        url: URL,
        method: HTTPMethod
    ) async throws -> APIResponse<T> {
        return try await performRequest(url: url, method: method, body: nil as String?)
    }
    
    private func performRequest<T: Codable, U: Codable>(
        url: URL,
        method: HTTPMethod,
        body: U?
    ) async throws -> APIResponse<T> {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw FeddyAPIError.decodingError(error)
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    break
                case 401:
                    throw FeddyAPIError.invalidAPIKey
                case 429:
                    throw FeddyAPIError.rateLimited
                case 400...499:
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw FeddyAPIError.serverError(errorResponse.error)
                    }
                    throw FeddyAPIError.serverError("Client error")
                default:
                    throw FeddyAPIError.serverError("Server error")
                }
            }
            
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(APIResponse<T>.self, from: data)
                return result
            } catch {
                throw FeddyAPIError.decodingError(error)
            }
        } catch {
            if error is FeddyAPIError {
                throw error
            }
            throw FeddyAPIError.networkError(error)
        }
    }
}