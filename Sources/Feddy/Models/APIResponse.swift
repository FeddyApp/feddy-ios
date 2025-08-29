import Foundation

public struct APIResponse<T: Codable>: Codable {
    public let success: Bool
    public let data: T?
    public let error: String?
    public let meta: ResponseMeta
    
    public struct ResponseMeta: Codable {
        public let timestamp: String
    }
}

public struct ErrorResponse: Codable {
    public let success: Bool
    public let error: String
    public let meta: ResponseMeta
    
    public struct ResponseMeta: Codable {
        public let timestamp: String
    }
}