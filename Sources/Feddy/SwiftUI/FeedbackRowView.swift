import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct FeedbackRowView: View {
    let feedback: FeedbackItem
    let onVote: () -> Void
    @State private var showingDetail = false
    
    public var body: some View {
        HStack(spacing: 12) {
            // Vote count on the left
            VStack(spacing: 4) {
                Button(action: onVote) {
                    Image(systemName: "arrowtriangle.up.fill")
                        .foregroundColor(voteButtonColor)
                        .font(.system(size: 16))
                }
                Text("\(feedback.voteCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(voteCountColor)
            }
            .frame(width: 50, height: 60)
            .background(voteBorderBackgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(voteBorderColor, lineWidth: voteBorderWidth)
            )
            .cornerRadius(8)
            
            // Content in the middle
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(feedback.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                    statusBadge
                }
                
                HStack {
                    Text(feedback.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if feedback.description.count > 100 {
                        Text("...")
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(16)
        #if os(iOS)
        .background(Color(UIColor.systemBackground))
        #else
        .background(Color.white)
        #endif
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            FeedbackDetailView(feedback: feedback)
        }
    }
    
    private var statusBadge: some View {
        Text(statusText.uppercased())
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .foregroundColor(.white)
            .cornerRadius(6)
    }
    
    private var statusText: String {
        switch feedback.status {
        case .planned:
            return "PLANNED"
        case .inProgress:
            return "IN PROGRESS"
        case .inReview:
            return "IN REVIEW"
        case .completed:
            return "COMPLETED"
        }
    }
    
    private var statusColor: Color {
        switch feedback.status {
        case .planned:
            return Color.purple
        case .inProgress:
            return Color.blue
        case .inReview:
            return Color(red: 0.0, green: 0.8, blue: 1.0) // Custom cyan color for iOS 14 compatibility
        case .completed:
            return Color.green
        }
    }
    
    // MARK: - Vote Status Colors
    
    private var voteButtonColor: Color {
        if let userVoted = feedback.userVoted, userVoted {
            return Color.orange // User has voted - Orange
        } else {
            return Color.gray   // User has not voted - Gray
        }
    }
    
    private var voteCountColor: Color {
        if let userVoted = feedback.userVoted, userVoted {
            return Color.orange // User has voted - Orange
        } else {
            return Color.primary // User has not voted - Default color
        }
    }
    
    // MARK: - Vote Border Styling
    
    private var voteBorderColor: Color {
        if let userVoted = feedback.userVoted, userVoted {
            return Color.orange // User has voted - Orange border
        } else {
            return Color.gray.opacity(0.3) // User has not voted - Light gray border
        }
    }
    
    private var voteBorderWidth: CGFloat {
        if let userVoted = feedback.userVoted, userVoted {
            return 2.0 // User has voted - Thicker border
        } else {
            return 1.0 // User has not voted - Thinner border
        }
    }
    
    private var voteBorderBackgroundColor: Color {
        if let userVoted = feedback.userVoted, userVoted {
            return Color.orange.opacity(0.1) // User has voted - Light orange background
        } else {
            return Color.clear // User has not voted - Transparent background
        }
    }
}

// MARK: - FeedbackDetailView

public struct FeedbackDetailView: View {
    let feedback: FeedbackItem
    @State private var comments: [CommentItem] = []
    @State private var isLoadingComments = false
    @State private var commentError: String?
    @State private var manager: FeedbackManager?
    @Environment(\.presentationMode) var presentationMode
    
    public init(feedback: FeedbackItem) {
        self.feedback = feedback
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with feedback info
                feedbackHeaderView
                    .padding(16)
                
                Divider()
                
                // Comments section
                commentsSection
                
                Divider()
                
                // Comment input
                FeedbackCommentInputView(feedbackId: feedback.id, manager: manager) {
                    await loadComments()
                }
                .padding(16)
            }
            #if os(iOS)
            .background(Color(UIColor.systemBackground))
            #else
            .background(Color.white)
            #endif
            .navigationTitle("Feedback Details")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            setupManager()
            Task {
                await loadComments()
            }
        }
    }
    
    private var feedbackHeaderView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and status
            HStack {
                Text(feedback.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                statusBadge
            }
            
            // Description
            Text(feedback.description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            // Vote count and type info
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "arrowtriangle.up.fill")
                        .foregroundColor(voteButtonColor)
                        .font(.caption)
                    Text("\(feedback.voteCount)")
                        .font(.caption)
                        .foregroundColor(voteCountColor)
                }
                
                Spacer()
                
                Text(feedback.type.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
                
                Text(feedback.priority.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor.opacity(0.1))
                    .foregroundColor(priorityColor)
                    .cornerRadius(4)
            }
        }
    }
    
    private var statusBadge: some View {
        Text(statusText.uppercased())
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .foregroundColor(.white)
            .cornerRadius(6)
    }
    
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Comments")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                if isLoadingComments {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            if let error = commentError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
            }
            
            FeedbackCommentListView(comments: comments)
        }
    }
    
    private func setupManager() {
        if manager == nil {
            manager = FeedbackManager()
        }
    }
    
    private func loadComments() async {
        guard let manager = manager else { return }
        
        await MainActor.run {
            isLoadingComments = true
            commentError = nil
        }
        
        do {
            let response = try await manager.apiClient.getComments(feedbackId: feedback.id)
            await MainActor.run {
                comments = response.comments
                isLoadingComments = false
            }
        } catch {
            await MainActor.run {
                commentError = "Failed to load comments: \(error.localizedDescription)"
                isLoadingComments = false
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusText: String {
        switch feedback.status {
        case .planned: return "PLANNED"
        case .inProgress: return "IN PROGRESS"
        case .inReview: return "IN REVIEW"
        case .completed: return "COMPLETED"
        }
    }
    
    private var statusColor: Color {
        switch feedback.status {
        case .planned: return Color.purple
        case .inProgress: return Color.blue
        case .inReview: return Color(red: 0.0, green: 0.8, blue: 1.0)
        case .completed: return Color.green
        }
    }
    
    private var voteButtonColor: Color {
        if let userVoted = feedback.userVoted, userVoted {
            return Color.orange
        } else {
            return Color.gray
        }
    }
    
    private var voteCountColor: Color {
        if let userVoted = feedback.userVoted, userVoted {
            return Color.orange
        } else {
            return Color.primary
        }
    }
    
    private var priorityColor: Color {
        switch feedback.priority {
        case .low: return Color.green
        case .medium: return Color.orange
        case .high: return Color.red
        case .critical: return Color.purple
        }
    }
}