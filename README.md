# Feddy iOS SDK

A comprehensive feedback collection SDK for iOS and macOS applications.

## Installation

### Swift Package Manager

Add Feddy to your project using Swift Package Manager:

#### Xcode UI
1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter the repository URL: `https://github.com/FeddyApp/feddy-ios.git`
3. Choose your version requirements:
   - **Up to Next Major**: `1.0.0` (Recommended)
   - **Exact Version**: `1.0.0`
   - **Branch**: `main` (Latest development)

#### Package.swift
Add Feddy as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/FeddyApp/feddy-ios.git", from: "1.0.0")
]
```

Then add it to your target:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["Feddy"]
    )
]
```

## Quick Start

### 1. Configure the SDK

#### Basic Configuration

```swift
import Feddy

// Basic configuration
Feddy.configure(apiKey: "feddy_4ffa601fd3249c83a41287f9e2b8c172")

// Optionally set user information
Feddy.updateUser(
    userId: "user123",
    email: "user@example.com", 
    name: "John Doe"
)
```

#### Configuration with Debug Logging

```swift
import Feddy

// Enable debug logging for development
Feddy.configure(
    apiKey: "feddy_4ffa601fd3249c83a41287f9e2b8c172",
    enableDebugLogging: true
)

// In your AppDelegate
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure Feddy with debug logging enabled for development builds
        #if DEBUG
        Feddy.configure(
            apiKey: "feddy_4ffa601fd3249c83a41287f9e2b8c172",
            enableDebugLogging: true
        )
        #else
        Feddy.configure(apiKey: "feddy_4ffa601fd3249c83a41287f9e2b8c172")
        #endif
        
        return true
    }
}
```

### 2. SwiftUI Integration

```swift
import SwiftUI
import Feddy

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                // Your app content
                
                // Add feedback list view
                NavigationLink("View Feedback", destination: {
                    Feddy.FeedbackListView()
                })
                
                // Add feedback submission view
                NavigationLink("Submit Feedback", destination: {
                    Feddy.FeedbackSubmitView()
                })
            }
        }
    }
}
```

### 3. UIKit Integration

```swift
import UIKit
import Feddy

class ViewController: UIViewController {
    
    @IBAction func showFeedbackList(_ sender: Any) {
        Feddy.presentFeedbackList(from: self)
    }
    
    @IBAction func showFeedbackSubmit(_ sender: Any) {
        Feddy.presentFeedbackSubmit(from: self)
    }
}
```

## Features

- ✅ **Cross-platform**: iOS 14+ and macOS 13+ support
- ✅ **SwiftUI & UIKit**: Native integration for both frameworks
- ✅ **Feedback Types**: Bug reports, feature requests, improvements, questions
- ✅ **Priority Levels**: Low, medium, high, critical
- ✅ **Voting System**: Users can vote on feedback
- ✅ **Screenshot Support**: Attach screenshots to feedback
- ✅ **Device Info**: Automatic device and app version collection
- ✅ **Async/Await**: Modern Swift concurrency support
- ✅ **Thread Safe**: Full Sendable protocol compliance

## API Reference

### Configuration

```swift
// Basic configuration
Feddy.configure(apiKey: "feddy_4ffa601fd3249c83a41287f9e2b8c172")

// Configuration with debug logging
Feddy.configure(
    apiKey: "feddy_4ffa601fd3249c83a41287f9e2b8c172",
    enableDebugLogging: true
)

// Update user information
Feddy.updateUser(userId: "123", email: "user@example.com", name: "John")

// Check configuration status
if Feddy.isConfigured {
    // SDK is ready to use
}

// Check if SDK is fully initialized
if Feddy.isInitialized {
    // SDK has completed initialization
}
```

### SwiftUI Views

```swift
// Feedback list view
Feddy.FeedbackListView()

// Feedback submission view  
Feddy.FeedbackSubmitView()
```

### UIKit Presentation

```swift
// Present feedback list
Feddy.presentFeedbackList(from: viewController)

// Present feedback submission
Feddy.presentFeedbackSubmit(from: viewController)
```

## Debug & Troubleshooting

### Debug Logging

The Feddy iOS SDK includes basic debug logging to help you troubleshoot integration issues during development.

#### Example Debug Output

When debug logging is enabled, you'll see output like this in Xcode console:

```
🚀 [Feddy] Starting SDK configuration...
✅ [Feddy] SDK configured successfully
📊 [Feddy] Configuration details:
  - API Key: feddy_4ffa601fd...
  - Base URL: https://feddy.app
  - Debug Logging: true
👤 [Feddy] Current user state:
  - User ID: user123
  - Email: user@example.com
```

#### Common Debug Scenarios

**1. API Key Issues**
```swift
⚠️ [Feddy] API key format warning: Expected key to start with 'feddy_', got: abc123...
```

**2. Configuration Issues**
```swift
⚠️ [Feddy] Attempting to update user before SDK configuration. Call Feddy.configure() first.
❌ [Feddy] Cannot create FeedbackListView: SDK not configured. Call Feddy.configure() first.
```

### Best Practices

1. **Enable debug logging only in DEBUG builds**:
   ```swift
   #if DEBUG
   Feddy.configure(apiKey: "your-key", enableDebugLogging: true)
   #else
   Feddy.configure(apiKey: "your-key")
   #endif
   ```

2. **Check initialization status before using SDK**:
   ```swift
   guard Feddy.isConfigured && Feddy.isInitialized else {
       print("Feddy SDK not ready")
       return
   }
   ```

## Version History

### v1.0.0
- Initial release
- Complete feedback management system
- SwiftUI and UIKit support
- Cross-platform iOS/macOS compatibility
- Swift 6.0 concurrency support

## Requirements

- **iOS**: 14.0+
- **macOS**: 13.0+
- **Swift**: 6.1+
- **Xcode**: 15.0+

## License

Copyright © 2025 FeddyApp. All rights reserved.

## Support

For support and documentation, visit: https://feddy.app