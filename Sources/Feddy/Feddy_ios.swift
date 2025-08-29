import Foundation
import SwiftUI
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

public struct Feddy {
    
    // Simple static configuration - fixed API URL
    @MainActor private static var _apiKey: String = ""
    private static let _baseURL: String = "https://feddy.app"
    @MainActor private static var _user = FeddyUser()
    
    @MainActor public static var apiKey: String {
        return _apiKey
    }
    
    public static var baseURL: String {
        return _baseURL
    }
    
    @MainActor public static var user: FeddyUser {
        return _user
    }
    
    @MainActor public static var isConfigured: Bool {
        return !_apiKey.isEmpty
    }
    
    // MARK: - Configuration
    
    @MainActor public static func configure(apiKey: String) {
        _apiKey = apiKey
    }
    
    // MARK: - User Management
    
    @MainActor public static func updateUser(userId: String? = nil, email: String? = nil, name: String? = nil) {
        if let userId = userId {
            _user.userId = userId
        }
        if let email = email {
            _user.email = email
        }
        if let name = name {
            _user.name = name
        }
    }
    
    // MARK: - SwiftUI Views
    
    @MainActor
    public static func FeedbackListView() -> some View {
        return FeddyFeedbackListView()
    }
    
    @MainActor
    public static func FeedbackSubmitView() -> some View {
        return FeddyFeedbackSubmitView()
    }
    
    // MARK: - UIKit Integration
    
    #if canImport(UIKit) && !os(watchOS)
    @MainActor
    public static func presentFeedbackList(from viewController: UIViewController, animated: Bool = true) {
        let hostingController = UIHostingController(rootView: FeddyFeedbackListView())
        let navController = UINavigationController(rootViewController: hostingController)
        viewController.present(navController, animated: animated)
    }
    
    @MainActor
    public static func presentFeedbackSubmit(from viewController: UIViewController, animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        let hostingController = UIHostingController(rootView: FeddyFeedbackSubmitView())
        let navController = UINavigationController(rootViewController: hostingController)
        viewController.present(navController, animated: animated)
    }
    #endif
}
