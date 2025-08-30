import Foundation

public struct FeedbackItem: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let type: FeedbackType
    public let priority: FeedbackPriority
    public let status: FeedbackStatus
    public let voteCount: Int
    public let userVoted: Bool?
    public let createdAt: String
    public let updatedAt: String
    
    private enum CodingKeys: String, CodingKey {
        case id, title, description, type, priority, status, voteCount, userVoted, createdAt, updatedAt
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        type = try container.decode(FeedbackType.self, forKey: .type)
        priority = try container.decode(FeedbackPriority.self, forKey: .priority)
        status = try container.decode(FeedbackStatus.self, forKey: .status)
        voteCount = try container.decode(Int.self, forKey: .voteCount)
        userVoted = try container.decodeIfPresent(Bool.self, forKey: .userVoted)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }
}

public enum FeedbackType: String, Codable, CaseIterable, Sendable {
    case bug = "bug"
    case feature = "feature"
    case improvement = "improvement"
    case question = "question"
    
    public var displayName: String {
        switch self {
        case .bug: return "Bug"
        case .feature: return "Feature"
        case .improvement: return "Improvement"
        case .question: return "Question"
        }
    }
    
    public var apiValue: String {
        return self.rawValue.uppercased()
    }
}

public enum FeedbackPriority: String, Codable, CaseIterable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    public var apiValue: String {
        return self.rawValue
    }
}

public enum FeedbackStatus: String, Codable, CaseIterable, Sendable {
    case inReview = "IN_REVIEW"
    case planned = "PLANNED"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    
    public var displayName: String {
        switch self {
        case .inReview: return "In Review"
        case .planned: return "Planned"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        }
    }
}

public struct FeedbackListResponse: Codable, Sendable {
    public let feedbacks: [FeedbackItem]
    public let total: Int
    public let project: ProjectInfo
    
    public struct ProjectInfo: Codable, Sendable {
        public let id: String
        public let name: String
    }
}

public struct FeedbackSubmission: Codable {
    public let title: String
    public let description: String
    public let type: String
    public let priority: String?
    public let userEmail: String?
    public let userName: String?
    public let userAgent: String?
    public let deviceInfo: String?
    public let screenshot: String?
    public let logs: String?
    public let metadata: FeedbackMetadata
    
    public struct FeedbackMetadata: Codable, Sendable {
        public let userId: String
        public let platform: String
        public let appVersion: String?
        public let sdkVersion: String?
    }
}

public struct FeedbackSubmissionResponse: Codable, Sendable {
    public let id: String
    public let status: String
    public let project: ProjectInfo
    
    public struct ProjectInfo: Codable, Sendable {
        public let id: String
        public let name: String
    }
}

public struct VoteRequest: Codable {
    public let feedbackId: String
    public let userId: String
    public let userName: String?
    public let userEmail: String?
}

public struct VoteResponse: Codable, Sendable {
    public let feedbackId: String
    public let voteCount: Int
}
