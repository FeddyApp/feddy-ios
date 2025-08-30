import Foundation

struct APIEndpoints {
    static let getFeedbacks = "/api/feedback"
    static let submitFeedback = "/api/feedback/submit"
    static let voteFeedback = "/api/feedback/vote"
    static let getComments = "/api/feedback/comment"
    static let addComment = "/api/feedback/comment"
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}