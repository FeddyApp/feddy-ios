import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Comment Input Component

public struct FeedbackCommentInputView: View {
    let feedbackId: String
    let manager: FeedbackManager?
    let onCommentAdded: () async -> Void
    
    @State private var commentText = ""
    @State private var isSubmitting = false
    @State private var submitError: String?
    
    public init(
        feedbackId: String, 
        manager: FeedbackManager?,
        onCommentAdded: @escaping () async -> Void
    ) {
        self.feedbackId = feedbackId
        self.manager = manager
        self.onCommentAdded = onCommentAdded
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Error message
            if let error = submitError {
                Text(error)
                    .font(.title)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }
            
            // Input section
            HStack(spacing: 12) {
                // Text input - iOS 14 compatible
                TextField("Add a comment...", text: $commentText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isSubmitting)
                
                // Submit button
                Button(action: submitComment) {
                    if isSubmitting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(canSubmit ? .blue : .gray)
                    }
                }
                .disabled(!canSubmit || isSubmitting)
                .buttonStyle(.plain)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(canSubmit ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                )
            }
        }
        #if os(iOS)
        .background(Color(UIColor.systemBackground))
        #else
        .background(Color.white)
        #endif
    }
    
    private var canSubmit: Bool {
        !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        commentText.count <= 1000 &&
        manager != nil
    }
    
    private func submitComment() {
        guard let manager = manager, canSubmit else { return }
        
        let trimmedText = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        Task {
            await MainActor.run {
                isSubmitting = true
                submitError = nil
            }
            
            do {
                let comment = CommentRequest(
                    feedbackId: feedbackId,
                    userId: manager.getUserId(),
                    userName: nil, // Could be extended to get user name
                    userEmail: nil, // Could be extended to get user email
                    content: trimmedText
                )
                
                _ = try await manager.apiClient.addComment(comment)
                
                await MainActor.run {
                    commentText = ""
                    isSubmitting = false
                }
                
                // Refresh comments
                await onCommentAdded()
                
            } catch {
                await MainActor.run {
                    submitError = "Failed to submit comment: \(error.localizedDescription)"
                    isSubmitting = false
                }
            }
        }
    }
}

// MARK: - Comment List Component

public struct FeedbackCommentListView: View {
    let comments: [CommentItem]
    
    public init(comments: [CommentItem]) {
        self.comments = comments
    }
    
    public var body: some View {
        if comments.isEmpty {
            FeedbackEmptyCommentsView()
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(comments) { comment in
                        FeedbackCommentRowView(comment: comment)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }
}

// MARK: - Supporting Components

struct FeedbackCommentRowView: View {
    let comment: CommentItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // User type and date info
            HStack(spacing: 8) {
                // Comment type badge only (no username)
                commentTypeBadge
                
                Spacer()
                
                // Date format (YYYY-MM-DD)
                Text(dateFormatText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Comment content
            Text(comment.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            // Replies
            if let replies = comment.replies, !replies.isEmpty {
                VStack(spacing: 8) {
                    ForEach(replies) { reply in
                        FeedbackReplyRowView(reply: reply)
                    }
                }
                .padding(.leading, 16)
            }
        }
        .padding(12)
        .background(commentBackgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(commentBorderColor, lineWidth: 1)
        )
    }
    
    private var commentTypeBadge: some View {
        Text(comment.commentType.displayName.uppercased())
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeBackgroundColor)
            .foregroundColor(badgeTextColor)
            .cornerRadius(4)
    }
    
    private var badgeBackgroundColor: Color {
        switch comment.commentType {
        case .admin: return Color.red
        case .author: return Color.blue
        case .user: return Color.gray
        }
    }
    
    private var badgeTextColor: Color {
        return Color.white
    }
    
    private var commentBackgroundColor: Color {
        switch comment.commentType {
        case .admin:
            #if os(iOS)
            return Color(UIColor.systemBackground)
            #else
            return Color.white
            #endif
        case .author:
            return Color.blue.opacity(0.05)
        case .user:
            #if os(iOS)
            return Color(UIColor.systemGray6)
            #else
            return Color.gray.opacity(0.1)
            #endif
        }
    }
    
    private var commentBorderColor: Color {
        switch comment.commentType {
        case .admin: return Color.red.opacity(0.3)
        case .author: return Color.blue.opacity(0.3)
        case .user: return Color.gray.opacity(0.2)
        }
    }
    
    private var dateFormatText: String {
        // Try multiple date formats to handle different input formats
        let isoFormatter = ISO8601DateFormatter()
        let dateFormatter = DateFormatter()
        
        // First try ISO8601 format
        if let date = isoFormatter.date(from: comment.createdAt) {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.string(from: date)
        }
        
        // Try common date formats
        let commonFormats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]
        
        for format in commonFormats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: comment.createdAt) {
                dateFormatter.dateFormat = "yyyy-MM-dd"
                return dateFormatter.string(from: date)
            }
        }
        
        // If all parsing fails, show the original string or current date
        return comment.createdAt.isEmpty ? "Unknown" : comment.createdAt
    }
}

struct FeedbackReplyRowView: View {
    let reply: CommentItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                // Reply type badge only (no username or arrow)
                replyTypeBadge
                
                Spacer()
                
                // Date format (YYYY-MM-DD)
                Text(replyDateFormatText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(reply.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(replyBackgroundColor)
        .cornerRadius(6)
    }
    
    private var replyTypeBadge: some View {
        Text(reply.commentType.displayName.uppercased())
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(replyBadgeBackgroundColor)
            .foregroundColor(Color.white)
            .cornerRadius(3)
    }
    
    private var replyBadgeBackgroundColor: Color {
        switch reply.commentType {
        case .admin: return Color.red
        case .author: return Color.blue
        case .user: return Color.gray
        }
    }
    
    private var replyBackgroundColor: Color {
        switch reply.commentType {
        case .admin: return Color.red.opacity(0.05)
        case .author: return Color.blue.opacity(0.08)
        case .user: return Color.gray.opacity(0.05)
        }
    }
    
    private var replyDateFormatText: String {
        // Try multiple date formats to handle different input formats
        let isoFormatter = ISO8601DateFormatter()
        let dateFormatter = DateFormatter()
        
        // First try ISO8601 format
        if let date = isoFormatter.date(from: reply.createdAt) {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.string(from: date)
        }
        
        // Try common date formats
        let commonFormats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]
        
        for format in commonFormats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: reply.createdAt) {
                dateFormatter.dateFormat = "yyyy-MM-dd"
                return dateFormatter.string(from: date)
            }
        }
        
        // If all parsing fails, show the original string or current date
        return reply.createdAt.isEmpty ? "Unknown" : reply.createdAt
    }
}

struct FeedbackEmptyCommentsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left")
                .font(.system(size: 32))
                .foregroundColor(.gray)
            
            Text("No comments yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Be the first to add a comment!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(iOS)
        .background(Color(UIColor.systemBackground))
        #else
        .background(Color.white)
        #endif
    }
}
