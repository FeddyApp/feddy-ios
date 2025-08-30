import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct FeddyFeedbackSubmitView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isInitialized = false
    @State private var manager: FeedbackManager?
    
    @State private var title = ""
    @State private var description = ""
    @State private var email = ""
    @State private var selectedType = FeedbackType.bug
    @State private var screenshot: Any?
    @State private var isShowingImagePicker = false
    @State private var isSubmitting = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack {
                if isInitialized {
                    formContent
                } else {
                    ProgressView("Initializing...")
                }
            }
            .navigationTitle("Submit Feedback")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Submit") {
                    submitFeedback()
                }
                    .disabled(title.isEmpty || description.isEmpty || isSubmitting || !isInitialized)
            )
            #endif
            #if canImport(UIKit)
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(selectedImage: $screenshot)
            }
            #endif
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Feedback"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertMessage.contains("success") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
            .onAppear {
                Task {
                    await initializeManager()
                    // Load saved email from user settings
                    email = Feddy.user.email ?? ""
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
    
    private var formContent: some View {
        Form {
            Section(header:
                Text("CATEGORY")
                    .font(.caption)
                    .foregroundColor(.secondary)
            ) {
                HStack {
                    Text("Type")
                    Spacer()
                    Picker("", selection: $selectedType) {
                        ForEach(FeedbackType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            Section(header:
                Text("FEEDBACK DETAILS")
                    .font(.caption)
                    .foregroundColor(.secondary)
            ) {
                TextField("Title", text: $title)
                #if os(iOS)
                if #available(iOS 16.0, *) {
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                } else {
                    TextField("Description", text: $description)
                        .lineLimit(3)
                }
                #else
                TextField("Description", text: $description)
                    .lineLimit(3)
                #endif
            }
            
            Section(header:
                Text("Email (OPTIONAL)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            ) {
                TextField("Email", text: $email)
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                    #endif
            }
            
//            #if canImport(UIKit)
//            Section(header: Text("Screenshot (Optional)")) {
//                if let screenshot = screenshot as? UIImage {
//                    Image(uiImage: screenshot)
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(height: 200)
//                    Button("Remove Screenshot") {
//                        self.screenshot = nil
//                    }
//                    .foregroundColor(.red)
//                } else {
//                    Button("Add Screenshot") {
//                        isShowingImagePicker = true
//                    }
//                }
//            }
//            #endif
        }
    }
    
    private func submitFeedback() {
        guard let manager = manager else { return }
        isSubmitting = true
        
        // Save email to user settings if provided
        if !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Feddy.updateUser(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        Task {
            let success = await manager.submitFeedback(
                title: title,
                description: description,
                type: selectedType,
                priority: .medium,
                screenshot: screenshot
            )
            
            isSubmitting = false
            if success {
                alertMessage = "Feedback submitted successfully!"
                // Clear input fields after successful submission, but keep email
                title = ""
                description = ""
                selectedType = .bug
                screenshot = nil
                // Don't clear email as it's saved in user settings
            } else {
                alertMessage = manager.error?.localizedDescription ?? "Failed to submit feedback"
            }
            showingAlert = true
        }
    }
}

#if canImport(UIKit)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: Any?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
#endif

#Preview {
    FeddyFeedbackSubmitView()
}

