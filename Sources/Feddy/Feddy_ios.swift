import Foundation
import SwiftUI
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

public struct Feddy {
    
    // SDK version
    public static let sdkVersion = "1.0.0"
    
    // Simple static configuration - fixed API URL
    @MainActor private static var _apiKey: String = ""
    // private static let _baseURL: String = "https://feddy.app"
    private static let _baseURL: String = "http://localhost:3000"
    @MainActor private static var _user = FeddyUser()
    @MainActor private static var _isInitialized: Bool = false
    
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
    
    @MainActor public static var isInitialized: Bool {
        return _isInitialized
    }
    
    // MARK: - Configuration
    
    @MainActor public static func configure(apiKey: String, enableDebugLogging: Bool = false) {
        if enableDebugLogging {
            print("🚀 [Feddy] Starting SDK configuration...")
        }
        
        // Validate API key format
        guard !apiKey.isEmpty else {
            print("❌ [Feddy] Configuration failed: API key cannot be empty")
            return
        }
        
        if !apiKey.hasPrefix("feddy_") {
            print("⚠️ [Feddy] API key format warning: Expected key to start with 'feddy_', got: \(apiKey.prefix(10))...")
        }
        
        // Store configuration
        _apiKey = apiKey
        _isInitialized = true
        
        if enableDebugLogging {
            print("✅ [Feddy] SDK configured successfully")
            print("📊 [Feddy] Configuration details:")
            print("  - API Key: \(apiKey.prefix(15))...")
            print("  - Base URL: \(_baseURL)")
            print("  - Debug Logging: \(enableDebugLogging)")
            
            // Log current user state
            let hasUserId = _user.userId?.isEmpty == false
            let hasEmail = _user.email?.isEmpty == false
            let hasName = _user.name?.isEmpty == false
            
            if hasUserId || hasEmail || hasName {
                print("👤 [Feddy] Current user state:")
                if let userId = _user.userId, !userId.isEmpty { 
                    print("  - User ID: \(userId)") 
                }
                if let email = _user.email, !email.isEmpty { 
                    print("  - Email: \(email)") 
                }
                if let name = _user.name, !name.isEmpty { 
                    print("  - Name: \(name)") 
                }
            } else {
                print("👤 [Feddy] No user information set")
            }
        }
    }
    
    // MARK: - User Management
    
    @MainActor public static func updateUser(userId: String? = nil, email: String? = nil, name: String? = nil) {
        print("[Feddy] 👤 updateUser called with:")
        print("[Feddy] 👤   - userId: \(userId ?? "nil")")
        print("[Feddy] 👤   - email: \(email ?? "nil")")
        print("[Feddy] 👤   - name: \(name ?? "nil")")
        
        guard isConfigured else {
            print("⚠️ [Feddy] Attempting to update user before SDK configuration. Call Feddy.configure() first.")
            return
        }
        
        print("[Feddy] 👤 Current user before update:")
        print("[Feddy] 👤   - current userId: \(_user.userId ?? "nil")")
        print("[Feddy] 👤   - current email: \(_user.email ?? "nil")")
        print("[Feddy] 👤   - current name: \(_user.name ?? "nil")")
        
        var updateDetails: [String] = []
        
        if let userId = userId {
            _user.userId = userId
            updateDetails.append("User ID: \(userId)")
        }
        if let email = email {
            _user.email = email
            updateDetails.append("Email: \(email)")
        }
        if let name = name {
            _user.name = name
            updateDetails.append("Name: \(name)")
        }
        
        if !updateDetails.isEmpty {
            print("👤 [Feddy] User updated: \(updateDetails.joined(separator: ", "))")
        }
        
        print("[Feddy] 👤 Final user state after update:")
        print("[Feddy] 👤   - final userId: \(_user.userId ?? "nil")")
        print("[Feddy] 👤   - final email: \(_user.email ?? "nil")")
        print("[Feddy] 👤   - final name: \(_user.name ?? "nil")")
    }
    
    // MARK: - User Data Management
    
    @MainActor public static func resetUserData() {
        guard isConfigured else {
            print("⚠️ [Feddy] Attempting to reset user data before SDK configuration. Call Feddy.configure() first.")
            return
        }
        
        print("[Feddy] 🔄 Resetting user data...")
        
        // Clear UserDefaults manually since we can't call mutating method on static property
        UserDefaults.standard.removeObject(forKey: FeddyUser.userIdKey)
        UserDefaults.standard.removeObject(forKey: FeddyUser.userEmailKey)
        UserDefaults.standard.removeObject(forKey: FeddyUser.userNameKey)
        
        // Recreate user with fresh data
        _user = FeddyUser()
        
        print("[Feddy] ✅ User data reset completed")
    }
    
    @MainActor public static func hasPersistentUserData() -> Bool {
        let hasPersistentData = FeddyUser.hasPersistentData()
        print("[Feddy] 🔍 Has persistent user data: \(hasPersistentData)")
        return hasPersistentData
    }
    
    // MARK: - SwiftUI Views
    
    @MainActor
    public static func FeedbackListView() -> some View {
        guard isConfigured else {
            print("❌ [Feddy] Cannot create FeedbackListView: SDK not configured. Call Feddy.configure() first.")
            return AnyView(Text("Feddy SDK not configured").foregroundColor(.red))
        }
        
        return AnyView(FeddyFeedbackListView())
    }
    
    @MainActor
    public static func FeedbackSubmitView() -> some View {
        guard isConfigured else {
            print("❌ [Feddy] Cannot create FeedbackSubmitView: SDK not configured. Call Feddy.configure() first.")
            return AnyView(Text("Feddy SDK not configured").foregroundColor(.red))
        }
        
        return AnyView(FeddyFeedbackSubmitView())
    }
    
    // MARK: - UIKit Integration
    
    #if canImport(UIKit) && !os(watchOS)
    @MainActor
    public static var viewController: UIViewController {
        guard isConfigured else {
            print("❌ [Feddy] Cannot create viewController: SDK not configured. Call Feddy.configure() first.")
            let errorVC = UIViewController()
            errorVC.view.backgroundColor = .systemBackground
            let label = UILabel()
            label.text = "Feddy SDK not configured"
            label.textColor = .systemRed
            label.textAlignment = .center
            errorVC.view.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: errorVC.view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: errorVC.view.centerYAnchor)
            ])
            return errorVC
        }
        
        let hostingController = UIHostingController(rootView: FeddyFeedbackListView(embedInNavigationView: false))
        hostingController.title = "Feedback"
        return hostingController
    }
    
    @MainActor
    public static func presentFeedbackList(from viewController: UIViewController, animated: Bool = true) {
        guard isConfigured else {
            print("❌ [Feddy] Cannot present FeedbackListView: SDK not configured. Call Feddy.configure() first.")
            return
        }
        
        let hostingController = UIHostingController(rootView: FeddyFeedbackListView())
        let navController = UINavigationController(rootViewController: hostingController)
        
        viewController.present(navController, animated: animated)
    }
    
    @MainActor
    public static func presentFeedbackSubmit(from viewController: UIViewController, animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        guard isConfigured else {
            print("❌ [Feddy] Cannot present FeedbackSubmitView: SDK not configured. Call Feddy.configure() first.")
            completion?(false)
            return
        }
        
        let hostingController = UIHostingController(rootView: FeddyFeedbackSubmitView())
        let navController = UINavigationController(rootViewController: hostingController)
        
        viewController.present(navController, animated: animated) {
            completion?(true)
        }
    }
    #endif
}

// MARK: - UIViewController Extension for WishKit-like API
#if canImport(UIKit) && !os(watchOS)
extension UIViewController {
    @MainActor
    public func withNavigation() -> UINavigationController {
        return UINavigationController(rootViewController: self)
    }
}
#endif
