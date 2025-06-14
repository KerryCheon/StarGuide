import SwiftUI
import FirebaseStorage
import FirebaseAuth

struct UploadView: View {
    @State private var image: UIImage?
    @State private var showImagePicker = false
    @State private var uploadProgress: Double = 0
    @State private var isUploading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var downloadURL: URL?
    
    // Storage reference
    private var storageRef: StorageReference {
        Storage.storage().reference()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .padding()
                
                uploadProgressView
                
                uploadButton
                
                if let url = downloadURL {
                    downloadURLView(url: url)
                }
            } else {
                selectImageButton
            }
        }
        .padding()
        .alert("Upload Status", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $image) {
                showImagePicker = false
            }
        }
    }
    
    // MARK: - Subviews
    
    private var uploadProgressView: some View {
        VStack {
            ProgressView(value: uploadProgress, total: 1.0)
                .padding(.horizontal)
            Text("\(Int(uploadProgress * 100))%")
                .font(.caption)
        }
        .opacity(isUploading ? 1 : 0)
    }
    
    private var uploadButton: some View {
        Button(action: uploadImage) {
            Text(isUploading ? "Uploading..." : "Upload to Firebase")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isUploading || image == nil)
        .padding()
    }
    
    private var selectImageButton: some View {
        Button(action: { showImagePicker = true }) {
            Label("Select Image", systemImage: "photo")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .padding()
    }
    
    private func downloadURLView(url: URL) -> some View {
        VStack {
            Text("Uploaded to:")
                .font(.caption)
            Text(url.absoluteString)
                .font(.caption)
                .lineLimit(3)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.string = url.absoluteString
                    }) {
                        Label("Copy URL", systemImage: "doc.on.doc")
                    }
                }
        }
    }
    
    // MARK: - Upload Logic
    
    func uploadImage() {
        guard let image = image else {
            showAlert(message: "No image selected")
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            showAlert(message: "Failed to convert image to JPEG")
            return
        }
        
        // Create a unique filename with timestamp
        let timestamp = Date().timeIntervalSince1970
        let filename = "\(timestamp)_\(UUID().uuidString).jpg"
        let uploadRef = storageRef.child("uploads/\(filename)")
        
        startUpload(data: imageData, reference: uploadRef)
    }
    
    private func startUpload(data: Data, reference: StorageReference) {
        isUploading = true
        uploadProgress = 0
        downloadURL = nil
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let uploadTask = reference.putData(data, metadata: metadata)
        
        uploadTask.observe(.progress) { snapshot in
            uploadProgress = Double(snapshot.progress?.fractionCompleted ?? 0)
        }
        
        uploadTask.observe(.success) { _ in
            reference.downloadURL { url, error in
                isUploading = false
                
                if let error = error {
                    showAlert(message: "Failed to get download URL: \(error.localizedDescription)")
                    return
                }
                
                guard let url = url else {
                    showAlert(message: "Received invalid download URL")
                    return
                }
                
                downloadURL = url
                showAlert(message: "Upload completed successfully!")
            }
        }
        
        uploadTask.observe(.failure) { snapshot in
            isUploading = false
            if let error = snapshot.error {
                showAlert(message: "Upload failed: \(error.localizedDescription)")
            } else {
                showAlert(message: "Upload failed with unknown error")
            }
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}
