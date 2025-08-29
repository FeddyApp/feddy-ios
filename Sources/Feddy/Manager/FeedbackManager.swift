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
    
    private var apiClient: FeddyAPIClient {
        if let cached = _cachedAPIClient, cached.apiKey == Feddy.apiKey {
            return cached
        }
        let client = FeddyAPIClient(apiKey: Feddy.apiKey, baseURL: Feddy.baseURL)
        _cachedAPIClient = client
        return client
    }
    
    public init() {}
    
    @MainActor
    public func loadFeedbacks(status: FeedbackStatus? = nil) async {
        guard Feddy.isConfigured else {
            error = FeddyAPIError.invalidAPIKey
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let response = try await apiClient.getFeedbacks(status: status)
            feedbacks = response.feedbacks
        } catch {
            self.error = error
        }
        
        isLoading = false
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
            appVersion: getAppVersion()
        )
        
        let submission = FeedbackSubmission(
            title: title,
            description: description,
            type: type.rawValue,
            priority: priority.rawValue,
            userEmail: user.email,
            userName: user.name,
            userAgent: nil,
            deviceInfo: deviceInfo,
            screenshot: screenshotData,
            logs: nil,
            metadata: metadata
        )
        
        do {
            _ = try await apiClient.submitFeedback(submission)
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
        guard Feddy.isConfigured else {
            error = FeddyAPIError.invalidAPIKey
            return false
        }
        
        let user = Feddy.user
        guard let email = user.email else {
            error = FeddyAPIError.invalidAPIKey
            return false
        }
        
        let voteRequest = VoteRequest(
            feedbackId: feedbackId,
            voterEmail: email,
            voterName: user.name
        )
        
        do {
            _ = try await apiClient.voteFeedback(voteRequest)
            await loadFeedbacks()
            return true
        } catch {
            self.error = error
            return false
        }
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