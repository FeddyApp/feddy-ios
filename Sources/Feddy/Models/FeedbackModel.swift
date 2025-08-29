import Foundation

public struct FeedbackItem: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let type: FeedbackType
    public let priority: FeedbackPriority
    public let status: FeedbackStatus
    public let voteCount: Int
    public let createdAt: String
    public let updatedAt: String
}

public enum FeedbackType: String, Codable, CaseIterable, Sendable {
    case bug = "BUG"
    case feature = "FEATURE"
    case improvement = "IMPROVEMENT"
    case question = "QUESTION"
    
    public var displayName: String {
        switch self {
        case .bug: return "Bug Report"
        case .feature: return "Feature Request"
        case .improvement: return "Improvement"
        case .question: return "Question"
        }
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
}

public enum FeedbackStatus: String, Codable, CaseIterable, Sendable {
    case planned = "PLANNED"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    
    public var displayName: String {
        switch self {
        case .planned: return "Planned"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        }
    }
}

public struct FeedbackListResponse: Codable, Sendable {
    public let feedbacks: [FeedbackItem]
    public let pagination: PaginationInfo
    public let project: ProjectInfo
    
    public struct PaginationInfo: Codable, Sendable {
        public let total: Int
        public let limit: Int
        public let offset: Int
        public let hasMore: Bool
    }
    
    public struct ProjectInfo: Codable, Sendable {
        public let id: String
        public let name: String
    }
}

public struct FeedbackSubmission: Codable {
    public let title: String
    public let description: String
    public let type: String
    public let priority: String
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
    public let voterEmail: String
    public let voterName: String?
}

public struct VoteResponse: Codable, Sendable {
    public let voteId: String
    public let feedbackId: String
    public let voteCount: Int
    public let feedback: FeedbackBasicInfo
    public let project: ProjectInfo
    
    public struct FeedbackBasicInfo: Codable, Sendable {
        public let id: String
        public let title: String
    }
    
    public struct ProjectInfo: Codable, Sendable {
        public let id: String
        public let name: String
    }
}