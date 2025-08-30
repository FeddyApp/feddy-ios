import Foundation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
public class FeedbackManager: ObservableObject {
    @Published public var feedbacks: [FeedbackItem] = []
    @Published public var isLoading = false
    @Published public var error: Error?
    
    private var _cachedAPIClient: FeddyAPIClient?
    
    public var apiClient: FeddyAPIClient {
        if let cached = _cachedAPIClient, cached.apiKey == Feddy.apiKey {
            print("[FeedbackManager] 🔄 Using cached API client")
            return cached
        }
        print("[FeedbackManager] 🆕 Creating new API client with baseURL: \(Feddy.baseURL)")
        let client = FeddyAPIClient(apiKey: Feddy.apiKey, baseURL: Feddy.baseURL)
        _cachedAPIClient = client
        return client
    }
    
    public init() {}
    
    @MainActor
    public func loadFeedbacks(status: FeedbackStatus? = nil) async {
        print("[FeedbackManager] 🔄 Starting to load feedbacks...")
        print("[FeedbackManager] 🔧 Feddy.isConfigured: \(Feddy.isConfigured)")
        print("[FeedbackManager] 🔧 Feddy.apiKey: \(Feddy.apiKey.isEmpty ? "EMPTY" : "SET")")
        print("[FeedbackManager] 🔧 Feddy.baseURL: \(Feddy.baseURL)")
        
        guard Feddy.isConfigured else {
            print("[FeedbackManager] ❌ Feddy not configured, setting invalid API key error")
            error = FeddyAPIError.invalidAPIKey
            return
        }
        
        print("[FeedbackManager] 🔄 Setting isLoading = true")
        isLoading = true
        error = nil
        
        do {
            let user = Feddy.user
            print("[FeedbackManager] 📡 Calling API to get feedbacks with userId for vote status...")
            print("[FeedbackManager] 📡 Using userId: \(user.userId ?? "nil")")
            let response = try await apiClient.getFeedbacks(status: status, userId: user.userId)
            print("[FeedbackManager] ✅ API call successful, received \(response.feedbacks.count) feedbacks, total: \(response.total)")
            feedbacks = response.feedbacks
            print("[FeedbackManager] 📝 Updated feedbacks array with \(feedbacks.count) items")
        } catch {
            print("[FeedbackManager] ❌ Error loading feedbacks: \(error)")
            self.error = error
        }
        
        print("[FeedbackManager] 🔄 Setting isLoading = false")
        isLoading = false
        print("[FeedbackManager] ✅ Load feedbacks completed, isLoading = \(isLoading)")
    }
    
    @MainActor
    public func submitFeedback(
        title: String,
        description: String,
        type: FeedbackType = .bug,
        priority: FeedbackPriority = .medium,
        screenshot: Any? = nil
    ) async -> Bool {
        guard Feddy.isConfigured else {
            error = FeddyAPIError.invalidAPIKey
            return false
        }
        
        let user = Feddy.user
        
        isLoading = true
        error = nil
        
        let deviceInfo = getDeviceInfo()
        let screenshotData = getScreenshotData(from: screenshot)
        
        let metadata = FeedbackSubmission.FeedbackMetadata(
            userId: user.userId ?? "anonymous",
            platform: getPlatform(),
            appVersion: getAppVersion(),
            sdkVersion: Feddy.sdkVersion
        )
        
        let submission = FeedbackSubmission(
            title: title,
            description: description,
            type: type.apiValue,
            priority: priority.apiValue,
            userEmail: user.email,
            userName: user.name,
            userAgent: nil,
            deviceInfo: deviceInfo,
            screenshot: screenshotData,
            logs: nil,
            metadata: metadata
        )
        
        do {
            print("[FeedbackManager] 📡 Submitting feedback with priority: \(priority.displayName)")
            print("[FeedbackManager] 📡 SDK Version: \(Feddy.sdkVersion)")
            _ = try await apiClient.submitFeedback(submission)
            print("[FeedbackManager] ✅ Feedback submitted successfully")
            await loadFeedbacks()
            isLoading = false
            return true
        } catch {
            self.error = error
            isLoading = false
            return false
        }
    }
    
    @MainActor
    public func voteFeedback(_ feedbackId: String) async -> Bool {
        print("[FeedbackManager] 🗳️ Starting to vote for feedback: \(feedbackId)")
        print("[FeedbackManager] 🔧 Feddy.isConfigured: \(Feddy.isConfigured)")
        
        guard Feddy.isConfigured else {
            print("[FeedbackManager] ❌ Feddy not configured for voting")
            error = FeddyAPIError.invalidAPIKey
            return false
        }
        
        let user = Feddy.user
        print("[FeedbackManager] 👤 User info:")
        print("[FeedbackManager] 👤   - userId: \(user.userId ?? "nil")")
        print("[FeedbackManager] 👤   - email: \(user.email ?? "nil")")
        print("[FeedbackManager] 👤   - name: \(user.name ?? "nil")")
        
        guard let userId = user.userId else {
            print("[FeedbackManager] ❌ User ID is nil, cannot vote")
            error = FeddyAPIError.invalidAPIKey
            return false
        }
        
        let voteRequest = VoteRequest(
            feedbackId: feedbackId,
            userId: userId,
            userName: user.name,
            userEmail: user.email
        )
        print("[FeedbackManager] 📝 Vote request created:")
        print("[FeedbackManager] 📝   - feedbackId: \(voteRequest.feedbackId)")
        print("[FeedbackManager] 📝   - userId: \(voteRequest.userId)")
        print("[FeedbackManager] 📝   - userName: \(voteRequest.userName ?? "nil")")
        print("[FeedbackManager] 📝   - userEmail: \(voteRequest.userEmail ?? "nil")")
        
        do {
            print("[FeedbackManager] 📡 Calling API to submit vote...")
            _ = try await apiClient.voteFeedback(voteRequest)
            print("[FeedbackManager] ✅ Vote submitted successfully")
            print("[FeedbackManager] 🔄 Reloading feedbacks after vote...")
            await loadFeedbacks()
            return true
        } catch {
            print("[FeedbackManager] ❌ Error submitting vote: \(error)")
            self.error = error
            return false
        }
    }
    
    public func getUserId() -> String {
        return Feddy.user.userId ?? "anonymous_user"
    }
    
    @MainActor
    private func getDeviceInfo() -> String {
        #if canImport(UIKit)
        let device = UIDevice.current
        return "\(device.model) - \(device.systemName) \(device.systemVersion)"
        #else
        return "Unknown Device - Unknown OS Unknown"
        #endif
    }
    
    private func getScreenshotData(from screenshot: Any?) -> String? {
        #if canImport(UIKit)
        guard let uiImage = screenshot as? UIImage else { return nil }
        return uiImage.jpegData(compressionQuality: 0.8)?.base64EncodedString()
        #else
        return nil
        #endif
    }
    
    private func getPlatform() -> String {
        #if os(iOS)
        return "IOS"
        #elseif os(macOS)
        return "MACOS"
        #else
        return "UNKNOWN"
        #endif
    }
    
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}