import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct FeddyFeedbackListView: View {
    @State private var isInitialized = false
    @State private var manager: FeedbackManager?
    @State private var selectedStatus: FeedbackStatus = .inReview
    @State private var showingSubmitView = false
    let embedInNavigationView: Bool
    
    public init(embedInNavigationView: Bool = true) {
        self.embedInNavigationView = embedInNavigationView
    }
    
    public var body: some View {
        Group {
            if embedInNavigationView {
                NavigationView {
                    contentView
                }
            } else {
                contentView
            }
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 0) {
            if isInitialized, let manager = manager {
                // Segment control
                VStack {
                    Picker("Status", selection: $selectedStatus) {
                        Text("In Review").tag(FeedbackStatus.inReview)
                        Text("Planned").tag(FeedbackStatus.planned)
                        Text("In Progress").tag(FeedbackStatus.inProgress)
                        Text("Completed").tag(FeedbackStatus.completed)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
#if os(iOS)
                .background(Color(UIColor.systemGroupedBackground))
#else
                .background(Color.gray.opacity(0.1))
#endif
                
                // Feedback list
                FeedbackTabView(
                    status: selectedStatus,
                    manager: manager
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView("Initializing...")
            }
        }
#if os(iOS)
        .background(Color(UIColor.systemGroupedBackground))
#else
        .background(Color.gray.opacity(0.1))
#endif
        .navigationTitle("Feedback")
#if os(iOS)
        .navigationBarItems(
            trailing: Button(action: { showingSubmitView = true }) {
                Image(systemName: "plus")
            }
                .disabled(!isInitialized)
        )
#endif
        .sheet(isPresented: $showingSubmitView) {
            FeddyFeedbackSubmitView()
        }
        .onAppear {
            Task {
                await initializeManager()
                if isInitialized, let manager = manager {
                    await manager.loadFeedbacks(status: selectedStatus)
                }
            }
        }
        .onChange(of: selectedStatus) { newStatus in
            Task {
                if let manager = manager {
                    await manager.loadFeedbacks(status: newStatus)
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
    
}

struct FeedbackTabView: View {
    let status: FeedbackStatus
    @ObservedObject var manager: FeedbackManager
    
    private var filteredFeedbacks: [FeedbackItem] {
        manager.feedbacks.filter { $0.status == status }
    }
    
    var body: some View {
        VStack {
            if manager.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredFeedbacks.isEmpty {
                VStack {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No \(statusDisplayName.lowercased()) feedback")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredFeedbacks) { feedback in
                            FeedbackRowView(feedback: feedback) {
                                Task {
                                    await manager.voteFeedback(feedback.id)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .modifier(RefreshableModifier(status: status, manager: manager))
            }
        }
#if os(iOS)
        .background(Color(UIColor.systemGroupedBackground))
#else
        .background(Color.gray.opacity(0.1))
#endif
    }
    
    private var statusDisplayName: String {
        switch status {
        case .planned: return "Planned"
        case .inReview: return "In Review"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        }
    }
}

struct RefreshableModifier: ViewModifier {
    let status: FeedbackStatus
    @ObservedObject var manager: FeedbackManager
    
    func body(content: Content) -> some View {
        if #available(iOS 15.0, macOS 12.0, *) {
            content
                .refreshable {
                    await manager.loadFeedbacks(status: status)
                }
        } else {
            // iOS 14 fallback - Can add manual refresh button or other refresh mechanisms
            content
        }
    }
}

#Preview {
    FeddyFeedbackListView()
}
