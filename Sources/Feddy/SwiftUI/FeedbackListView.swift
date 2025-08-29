import SwiftUI

public struct FeddyFeedbackListView: View {
    @State private var isInitialized = false
    @State private var manager: FeedbackManager?
    @State private var selectedStatus: FeedbackStatus?
    @State private var showingSubmitView = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack {
                if isInitialized, let _ = manager {
                    statusPicker
                    feedbackList
                    Spacer()
                } else {
                    ProgressView("Initializing...")
                }
            }
            .navigationTitle("Feedback")
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingSubmitView = true }) {
                        Image(systemName: "plus")
                    }
                    .disabled(!isInitialized)
                }
            }
            #elseif os(macOS)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingSubmitView = true }) {
                        Image(systemName: "plus")
                    }
                    .disabled(!isInitialized)
                }
            }
            #endif
            .sheet(isPresented: $showingSubmitView) {
                FeddyFeedbackSubmitView()
            }
            .onAppear {
                Task {
                    await initializeManager()
                }
            }
            .task {
                if isInitialized, let manager = manager {
                    await manager.loadFeedbacks()
                }
            }
        }
    }
    
    @MainActor
    private func initializeManager() async {
        if !isInitialized {
            manager = FeedbackManager()
            isInitialized = true
        }
    }
    
    private var statusPicker: some View {
        Picker("Status", selection: $selectedStatus) {
            Text("All").tag(nil as FeedbackStatus?)
            ForEach(FeedbackStatus.allCases, id: \.self) { status in
                Text(status.displayName).tag(status as FeedbackStatus?)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        .onChange(of: selectedStatus) { status in
            Task {
                if let manager = manager {
                    await manager.loadFeedbacks(status: status)
                }
            }
        }
    }
    
    private var feedbackList: some View {
        Group {
            if let manager = manager {
                if manager.isLoading {
                    ProgressView("Loading...")
                } else if manager.feedbacks.isEmpty {
                    Text("No feedback available")
                        .foregroundColor(.secondary)
                } else {
                    List(manager.feedbacks) { feedback in
                        FeedbackRowView(feedback: feedback) {
                            Task {
                                await manager.voteFeedback(feedback.id)
                            }
                        }
                    }
                    .refreshable {
                        await manager.loadFeedbacks(status: selectedStatus)
                    }
                }
            } else {
                ProgressView("Initializing...")
            }
        }
    }
}

struct FeedbackRowView: View {
    let feedback: FeedbackItem
    let onVote: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(feedback.title)
                        .font(.headline)
                    Text(feedback.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                statusBadge
            }
            
            HStack {
                typeAndPriorityLabels
                Spacer()
                voteButton
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusBadge: some View {
        Text(feedback.status.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private var statusColor: Color {
        switch feedback.status {
        case .planned:
            return .blue
        case .inProgress:
            return .orange
        case .completed:
            return .green
        }
    }
    
    private var typeAndPriorityLabels: some View {
        HStack {
            Text(feedback.type.displayName)
                .font(.caption)
                .foregroundColor(.blue)
            Text("•")
                .foregroundColor(.secondary)
            Text(feedback.priority.displayName)
                .font(.caption)
                .foregroundColor(priorityColor)
        }
    }
    
    private var priorityColor: Color {
        switch feedback.priority {
        case .low:
            return .green
        case .medium:
            return .yellow
        case .high:
            return .orange
        case .critical:
            return .red
        }
    }
    
    private var voteButton: some View {
        Button(action: onVote) {
            HStack {
                Image(systemName: "hand.thumbsup")
                Text("\(feedback.voteCount)")
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
    }
}

#Preview {
    FeddyFeedbackListView()
}