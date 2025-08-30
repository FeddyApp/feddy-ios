import Feddy
import SwiftUI

// Debug logging usage example
@main
struct DebugExampleApp: App {
    init() {
        setupFeddyWithDebugLogging()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func setupFeddyWithDebugLogging() {
        // Enable debugging in development environment
        #if DEBUG
        Feddy.configure(
            apiKey: "feddy_4ffa601fd3249c83a41287f9e2b8c172",
            enableDebugLogging: true
        )
        #else
        // Don't enable debug logging in production environment
        Feddy.configure(
            apiKey: "feddy_4ffa601fd3249c83a41287f9e2b8c172",
            enableDebugLogging: false
        )
        #endif
        
        // Set user information to test logging functionality
        Feddy.updateUser(
            userId: "test_user_123",
            email: "test@example.com",
            name: "Debug Test User"
        )
    }
}

struct ContentView: View {
    @State private var showingFeedbackList = false
    @State private var showingFeedbackSubmit = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Feddy Debug Example")
                    .font(.title)
                    .padding()
                
                Group {
                    Button("Show Feedback List") {
                        showingFeedbackList = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Show Feedback Submit") {
                        showingFeedbackSubmit = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Test Configuration Status") {
                        testConfigurationStatus()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Update User Info") {
                        updateUserInfo()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Feddy Debug")
        }
        .sheet(isPresented: $showingFeedbackList) {
            NavigationView {
                Feddy.FeedbackListView()
                    .navigationTitle("Feedback List")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingFeedbackList = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingFeedbackSubmit) {
            NavigationView {
                Feddy.FeedbackSubmitView()
                    .navigationTitle("Submit Feedback")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingFeedbackSubmit = false
                            }
                        }
                    }
            }
        }
    }
    
    private func testConfigurationStatus() {
        print("🧪 Testing Configuration Status:")
        print("   - isConfigured: \(Feddy.isConfigured)")
        print("   - isInitialized: \(Feddy.isInitialized)")
        print("   - API Key: \(Feddy.apiKey.prefix(15))...")
        print("   - Base URL: \(Feddy.baseURL)")
    }
    
    private func updateUserInfo() {
        let randomId = Int.random(in: 1000...9999)
        Feddy.updateUser(
            userId: "updated_user_\(randomId)",
            email: "updated_\(randomId)@example.com",
            name: "Updated Test User \(randomId)"
        )
    }
}

#Preview {
    ContentView()
}