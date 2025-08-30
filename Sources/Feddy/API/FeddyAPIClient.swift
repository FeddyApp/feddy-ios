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

// MARK: - Comment Models

public struct CommentItem: Codable, Identifiable, Sendable {
    public let id: String
    public let content: String
    public let commentType: CommentType
    public let author: CommentAuthor
    public let parentId: String?
    public let replies: [CommentItem]?
    public let createdAt: String
    
    private enum CodingKeys: String, CodingKey {
        case id, content, commentType, author, parentId, replies, createdAt
    }
}

public enum CommentType: String, Codable, CaseIterable, Sendable {
    case admin = "ADMIN"
    case author = "AUTHOR"
    case user = "USER"
    
    public var displayName: String {
        switch self {
        case .admin: return "Admin"
        case .author: return "Author"
        case .user: return "User"
        }
    }
    
    public var badgeColor: String {
        switch self {
        case .admin: return "red"
        case .author: return "blue"
        case .user: return "gray"
        }
    }
}

public struct CommentAuthor: Codable, Sendable {
    public let userId: String
    public let userName: String?
    
    public var displayName: String {
        return userName ?? "Anonymous User"
    }
}

public struct CommentListResponse: Codable, Sendable {
    public let comments: [CommentItem]
    public let feedbackId: String
    public let pagination: CommentPagination
    
    public struct CommentPagination: Codable, Sendable {
        public let limit: Int
        public let offset: Int
        public let count: Int
    }
}

public struct CommentRequest: Codable {
    public let feedbackId: String
    public let userId: String
    public let userName: String?
    public let userEmail: String?
    public let content: String
    public let parentId: String?
    
    public init(
        feedbackId: String,
        userId: String,
        userName: String? = nil,
        userEmail: String? = nil,
        content: String,
        parentId: String? = nil
    ) {
        self.feedbackId = feedbackId
        self.userId = userId
        self.userName = userName
        self.userEmail = userEmail
        self.content = content
        self.parentId = parentId
    }
}

public struct CommentResponse: Codable, Sendable {
    public let commentId: String
    public let feedbackId: String
    public let commentType: CommentType
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
        userId: String? = nil
    ) async throws -> FeedbackListResponse {
        print("[FeddyAPI] 🔍 Getting feedbacks with status: \(status?.rawValue ?? "all"), userId: \(userId ?? "nil")")
        
        var components = URLComponents(string: baseURL + APIEndpoints.getFeedbacks)!
        var queryItems: [URLQueryItem] = []
        
        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status.rawValue))
        }
        if let userId = userId {
            queryItems.append(URLQueryItem(name: "userId", value: userId))
        }
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else {
            print("[FeddyAPI] ❌ Invalid URL constructed")
            throw FeddyAPIError.invalidURL
        }
        
        print("[FeddyAPI] 🌐 Request URL: \(url.absoluteString)")
        
        let response: APIResponse<FeedbackListResponse> = try await performRequest(
            url: url,
            method: .GET
        )
        
        print("[FeddyAPI] 📦 API Response received - success: \(response.success)")
        
        guard let data = response.data else {
            let errorMessage = response.error ?? "Unknown error"
            print("[FeddyAPI] ❌ No data in response, error: \(errorMessage)")
            throw FeddyAPIError.serverError(errorMessage)
        }
        
        print("[FeddyAPI] ✅ Successfully got \(data.feedbacks.count) total feedbacks: \(data.total)")
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
            let errorMessage = response.error ?? "Unknown error"
            throw FeddyAPIError.serverError(errorMessage)
        }
        
        return data
    }
    
    public func voteFeedback(_ vote: VoteRequest) async throws -> VoteResponse {
        print("[FeddyAPI] 🗳️ Submitting vote for feedback: \(vote.feedbackId)")
        print("[FeddyAPI] 🗳️ User ID: \(vote.userId)")
        print("[FeddyAPI] 🗳️ User email: \(vote.userEmail ?? "nil")")
        print("[FeddyAPI] 🗳️ User name: \(vote.userName ?? "nil")")
        
        guard let url = URL(string: baseURL + APIEndpoints.voteFeedback) else {
            print("[FeddyAPI] ❌ Invalid URL for vote endpoint")
            throw FeddyAPIError.invalidURL
        }
        
        print("[FeddyAPI] 🌐 Vote request URL: \(url.absoluteString)")
        
        let response: APIResponse<VoteResponse> = try await performRequest(
            url: url,
            method: .POST,
            body: vote
        )
        
        print("[FeddyAPI] 📦 Vote API Response received - success: \(response.success)")
        
        guard let data = response.data else {
            let errorMessage = response.error ?? "Unknown error"
            print("[FeddyAPI] ❌ No data in vote response, error: \(errorMessage)")
            throw FeddyAPIError.serverError(errorMessage)
        }
        
        print("[FeddyAPI] ✅ Vote submitted successfully for feedback: \(data.feedbackId)")
        print("[FeddyAPI] ✅ Updated vote count: \(data.voteCount)")
        return data
    }
    
    public func getComments(
        feedbackId: String,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> CommentListResponse {
        print("[FeddyAPI] 💬 Getting comments for feedback: \(feedbackId)")
        print("[FeddyAPI] 💬 Limit: \(limit), Offset: \(offset)")
        
        var components = URLComponents(string: baseURL + APIEndpoints.getComments)!
        components.queryItems = [
            URLQueryItem(name: "feedbackId", value: feedbackId),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]
        
        guard let url = components.url else {
            print("[FeddyAPI] ❌ Invalid URL for comments endpoint")
            throw FeddyAPIError.invalidURL
        }
        
        print("[FeddyAPI] 🌐 Comments request URL: \(url.absoluteString)")
        
        let response: APIResponse<CommentListResponse> = try await performRequest(
            url: url,
            method: .GET
        )
        
        print("[FeddyAPI] 📦 Comments API Response received - success: \(response.success)")
        
        guard let data = response.data else {
            let errorMessage = response.error ?? "Unknown error"
            print("[FeddyAPI] ❌ No data in comments response, error: \(errorMessage)")
            throw FeddyAPIError.serverError(errorMessage)
        }
        
        print("[FeddyAPI] ✅ Successfully got \(data.comments.count) comments")
        return data
    }
    
    public func addComment(_ comment: CommentRequest) async throws -> CommentResponse {
        print("[FeddyAPI] 💬 Adding comment to feedback: \(comment.feedbackId)")
        print("[FeddyAPI] 💬 User ID: \(comment.userId)")
        print("[FeddyAPI] 💬 Content length: \(comment.content.count) characters")
        print("[FeddyAPI] 💬 Parent ID: \(comment.parentId ?? "nil")")
        
        guard let url = URL(string: baseURL + APIEndpoints.addComment) else {
            print("[FeddyAPI] ❌ Invalid URL for add comment endpoint")
            throw FeddyAPIError.invalidURL
        }
        
        print("[FeddyAPI] 🌐 Add comment request URL: \(url.absoluteString)")
        
        let response: APIResponse<CommentResponse> = try await performRequest(
            url: url,
            method: .POST,
            body: comment
        )
        
        print("[FeddyAPI] 📦 Add comment API Response received - success: \(response.success)")
        
        guard let data = response.data else {
            let errorMessage = response.error ?? "Unknown error"
            print("[FeddyAPI] ❌ No data in add comment response, error: \(errorMessage)")
            throw FeddyAPIError.serverError(errorMessage)
        }
        
        print("[FeddyAPI] ✅ Comment added successfully: \(data.commentId)")
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
        print("[FeddyAPI] 🚀 Making \(method.rawValue) request to: \(url.absoluteString)")
        print("[FeddyAPI] 🔑 Using API Key: \(apiKey.prefix(8))...")
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        if let body = body {
            do {
                let bodyData = try JSONEncoder().encode(body)
                request.httpBody = bodyData
                print("[FeddyAPI] 📤 Request body size: \(bodyData.count) bytes")
            } catch {
                print("[FeddyAPI] ❌ Failed to encode request body: \(error)")
                throw FeddyAPIError.decodingError(error)
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            print("[FeddyAPI] 📥 Response data size: \(data.count) bytes")
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[FeddyAPI] 📊 HTTP Status Code: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("[FeddyAPI] 📄 Response body: \(responseString)")
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    print("[FeddyAPI] ✅ Request successful")
                    break
                case 401:
                    print("[FeddyAPI] ❌ Invalid API key")
                    throw FeddyAPIError.invalidAPIKey
                case 429:
                    print("[FeddyAPI] ⏱️ Rate limited")
                    throw FeddyAPIError.rateLimited
                case 400...499:
                    print("[FeddyAPI] ❌ Client error: \(httpResponse.statusCode)")
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw FeddyAPIError.serverError(errorResponse.error)
                    }
                    throw FeddyAPIError.serverError("Client error")
                default:
                    print("[FeddyAPI] ❌ Server error: \(httpResponse.statusCode)")
                    throw FeddyAPIError.serverError("Server error")
                }
            }
            
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(APIResponse<T>.self, from: data)
                print("[FeddyAPI] ✅ Successfully decoded response")
                return result
            } catch {
                print("[FeddyAPI] ❌ Failed to decode response: \(error)")
                throw FeddyAPIError.decodingError(error)
            }
        } catch {
            if error is FeddyAPIError {
                throw error
            }
            print("[FeddyAPI] ❌ Network error: \(error)")
            throw FeddyAPIError.networkError(error)
        }
    }
}