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
    @State private var selectedType = FeedbackType.bug
    @State private var selectedPriority = FeedbackPriority.medium
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Submit") {
                        submitFeedback()
                    }
                    .disabled(title.isEmpty || description.isEmpty || isSubmitting || !isInitialized)
                }
            }
            #elseif os(macOS)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitFeedback()
                    }
                    .disabled(title.isEmpty || description.isEmpty || isSubmitting || !isInitialized)
                }
            }
            #endif
            #if canImport(UIKit)
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(selectedImage: $screenshot)
            }
            #endif
            .alert("Feedback", isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("success") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                Task {
                    await initializeManager()
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
                Section("Feedback Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Category") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(FeedbackType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Picker("Priority", selection: $selectedPriority) {
                        ForEach(FeedbackPriority.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                }
                
                #if canImport(UIKit)
                Section("Screenshot (Optional)") {
                    if let screenshot = screenshot as? UIImage {
                        Image(uiImage: screenshot)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                        Button("Remove Screenshot") {
                            self.screenshot = nil
                        }
                        .foregroundColor(.red)
                    } else {
                        Button("Add Screenshot") {
                            isShowingImagePicker = true
                        }
                    }
                }
                #endif
            }
    }
    
    private func submitFeedback() {
        guard let manager = manager else { return }
        isSubmitting = true
        
        Task {
            let success = await manager.submitFeedback(
                title: title,
                description: description,
                type: selectedType,
                priority: selectedPriority,
                screenshot: screenshot
            )
            
            isSubmitting = false
            if success {
                alertMessage = "Feedback submitted successfully!"
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