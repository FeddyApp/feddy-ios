import Foundation

public struct FeddyUser {
    // UserDefaults keys for persistence
    internal static let userIdKey = "FeddySDK_UserId"
    internal static let userEmailKey = "FeddySDK_UserEmail"
    internal static let userNameKey = "FeddySDK_UserName"
    
    public var userId: String? {
        didSet {
            // Save to UserDefaults whenever userId changes
            if let userId = userId {
                UserDefaults.standard.set(userId, forKey: Self.userIdKey)
                print("[FeddyUser] 💾 Saved userId to persistent storage: \(userId)")
            } else {
                UserDefaults.standard.removeObject(forKey: Self.userIdKey)
                print("[FeddyUser] 🗑️ Removed userId from persistent storage")
            }
        }
    }
    
    public var email: String? {
        didSet {
            // Save to UserDefaults whenever email changes
            if let email = email {
                UserDefaults.standard.set(email, forKey: Self.userEmailKey)
                print("[FeddyUser] 💾 Saved email to persistent storage: \(email)")
            } else {
                UserDefaults.standard.removeObject(forKey: Self.userEmailKey)
                print("[FeddyUser] 🗑️ Removed email from persistent storage")
            }
        }
    }
    
    public var name: String? {
        didSet {
            // Save to UserDefaults whenever name changes
            if let name = name {
                UserDefaults.standard.set(name, forKey: Self.userNameKey)
                print("[FeddyUser] 💾 Saved name to persistent storage: \(name)")
            } else {
                UserDefaults.standard.removeObject(forKey: Self.userNameKey)
                print("[FeddyUser] 🗑️ Removed name from persistent storage")
            }
        }
    }
    
    public init(userId: String? = nil, email: String? = nil, name: String? = nil) {
        print("[FeddyUser] 🔄 Initializing user...")
        
        // First, try to load existing data from UserDefaults
        let savedUserId = UserDefaults.standard.string(forKey: Self.userIdKey)
        let savedEmail = UserDefaults.standard.string(forKey: Self.userEmailKey)
        let savedName = UserDefaults.standard.string(forKey: Self.userNameKey)
        
        print("[FeddyUser] 📖 Loaded from persistent storage:")
        print("[FeddyUser] 📖   - savedUserId: \(savedUserId ?? "nil")")
        print("[FeddyUser] 📖   - savedEmail: \(savedEmail ?? "nil")")
        print("[FeddyUser] 📖   - savedName: \(savedName ?? "nil")")
        
        // Handle userId: use provided > saved > generate new
        if let providedUserId = userId {
            print("[FeddyUser] 🆔 Using provided userId: \(providedUserId)")
            self.userId = providedUserId
        } else if let savedUserId = savedUserId {
            print("[FeddyUser] 🆔 Using saved userId from storage: \(savedUserId)")
            self.userId = savedUserId
        } else {
            let generatedId = Self.generateAndSaveUserId()
            print("[FeddyUser] 🆔 No userId found, generated new persistent userId: \(generatedId)")
            self.userId = generatedId
        }
        
        // Handle email: use provided > saved
        if let providedEmail = email {
            self.email = providedEmail
        } else {
            self.email = savedEmail
        }
        
        // Handle name: use provided > saved
        if let providedName = name {
            self.name = providedName
        } else {
            self.name = savedName
        }
        
        print("[FeddyUser] ✅ User initialized with final state:")
        print("[FeddyUser] ✅   - userId: \(self.userId ?? "nil")")
        print("[FeddyUser] ✅   - email: \(self.email ?? "nil")")
        print("[FeddyUser] ✅   - name: \(self.name ?? "nil")")
    }
    
    private static func generateAndSaveUserId() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let randomString = UUID().uuidString.prefix(8)
        let generatedId = "user_\(timestamp)_\(randomString)"
        
        print("[FeddyUser] 🔧 Generating new persistent userId:")
        print("[FeddyUser] 🔧   - timestamp: \(timestamp)")
        print("[FeddyUser] 🔧   - random: \(randomString)")
        print("[FeddyUser] 🔧   - result: \(generatedId)")
        
        // Immediately save to UserDefaults
        UserDefaults.standard.set(generatedId, forKey: userIdKey)
        print("[FeddyUser] 💾 Saved generated userId to persistent storage")
        
        return generatedId
    }
    
    // Legacy function for compatibility
    static func generateUserId() -> String {
        return generateAndSaveUserId()
    }
    
    // Public method to reset user data (useful for testing or logout)
    public mutating func resetUserData() {
        print("[FeddyUser] 🔄 Resetting all user data...")
        
        UserDefaults.standard.removeObject(forKey: Self.userIdKey)
        UserDefaults.standard.removeObject(forKey: Self.userEmailKey)
        UserDefaults.standard.removeObject(forKey: Self.userNameKey)
        
        // Generate new userId
        self.userId = Self.generateAndSaveUserId()
        self.email = nil
        self.name = nil
        
        print("[FeddyUser] ✅ User data reset completed")
    }
    
    // Public method to check if user has persistent data
    public static func hasPersistentData() -> Bool {
        let hasUserId = UserDefaults.standard.string(forKey: userIdKey) != nil
        let hasEmail = UserDefaults.standard.string(forKey: userEmailKey) != nil
        let hasName = UserDefaults.standard.string(forKey: userNameKey) != nil
        
        print("[FeddyUser] 🔍 Checking persistent data: userId=\(hasUserId), email=\(hasEmail), name=\(hasName)")
        return hasUserId || hasEmail || hasName
    }
}