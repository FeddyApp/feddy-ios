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

```swift
import Feddy

// Configure with your API key
Feddy.configure(apiKey: "your-api-key-here")

// Optionally set user information
Feddy.updateUser(
    userId: "user123",
    email: "user@example.com", 
    name: "John Doe"
)
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
// Configure SDK
Feddy.configure(apiKey: "your-api-key")

// Update user information
Feddy.updateUser(userId: "123", email: "user@example.com", name: "John")

// Check configuration status
if Feddy.isConfigured {
    // SDK is ready to use
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

Copyright © 2024 FeddyApp. All rights reserved.

## Support

For support and documentation, visit: https://feddy.app