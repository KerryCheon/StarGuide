import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            UploadView()
                .tabItem {
                    Label("Upload", systemImage: "photo")
                }
            
            ARStarPointerWrapperView()
                .tabItem {
                    Label("Star Finder", systemImage: "location.north.line")
                }
        }
    }
}
