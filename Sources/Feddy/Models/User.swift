import Foundation

public struct FeddyUser {
    public var userId: String?
    public var email: String?
    public var name: String?
    
    public init(userId: String? = nil, email: String? = nil, name: String? = nil) {
        self.userId = userId ?? Self.generateUserId()
        self.email = email
        self.name = name
    }
    
    static func generateUserId() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let randomString = UUID().uuidString.prefix(8)
        return "user_\(timestamp)_\(randomString)"
    }
}