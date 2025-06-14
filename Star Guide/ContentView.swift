import SwiftUI
import FirebaseStorage

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var imageURL: URL?
    @State private var showImagePicker = false
    @State private var isUploading = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Star Guide Upload Demo")
                .font(.title2)

            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
            }

            Button("Choose Sky Photo") {
                showImagePicker = true
            }

            if isUploading {
                ProgressView("Uploading...")
            } else if let url = imageURL {
                Text("Uploaded Successfully!")
                Text(url.absoluteString)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage) {
                if let image = selectedImage {
                    uploadImage(image)
                }
            }
        }
    }

    func uploadImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        isUploading = true
        let storageRef = Storage.storage().reference()
        let imageID = UUID().uuidString
        let imageRef = storageRef.child("sky_images/\(imageID).jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        imageRef.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                print("Upload error: \(error.localizedDescription)")
                isUploading = false
                return
            }

            imageRef.downloadURL { url, error in
                isUploading = false
                if let url = url {
                    imageURL = url
                }
            }
        }
    }
}
