import SwiftUI
import RealityKit
import ARKit
import CoreLocation

struct ARStarPointerView: UIViewRepresentable {
    @ObservedObject var headingManager: LocationHeadingManager
    @Binding var errorMessage: String?
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Check AR availability
        guard ARWorldTrackingConfiguration.isSupported else {
            errorMessage = "AR is not supported on this device"
            return arView
        }
        
        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.worldAlignment = .gravityAndHeading
        
        // Check camera permissions
        if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            errorMessage = "Camera access is required for AR"
            return arView
        }
        
        do {
            try arView.session.run(config)
        } catch {
            errorMessage = "Failed to start AR session: \(error.localizedDescription)"
            return arView
        }
        
        // Create arrow entity
        let anchor = AnchorEntity(world: [0, 0, -1])
        let arrow = ModelEntity(
            mesh: .generateCone(height: 0.2, radius: 0.05),
            materials: [SimpleMaterial(color: .red, isMetallic: true)]
        )
        arrow.name = "arrow"
        anchor.addChild(arrow)
        arView.scene.anchors.append(anchor)
        
        context.coordinator.arrowEntity = arrow
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        guard let heading = headingManager.heading?.trueHeading else { return }
        
        let targetAzimuth: Double = 0.0 // Polaris (North Star)
        let angleToTarget = (targetAzimuth - heading).truncatingRemainder(dividingBy: 360)
        let radians = Float(angleToTarget * .pi / 180)
        
        if let arrow = context.coordinator.arrowEntity {
            arrow.transform.rotation = simd_quatf(angle: radians, axis: [0, 1, 0])
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var arrowEntity: ModelEntity?
    }
}

class LocationHeadingManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var heading: CLHeading?
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        
        // Request location authorization
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        
        startServices()
    }
    
    private func startServices() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        
        if manager.authorizationStatus == .authorizedAlways ||
           manager.authorizationStatus == .authorizedWhenInUse {
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.headingFilter = 1
            manager.startUpdatingHeading()
            manager.startUpdatingLocation()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        startServices()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}

struct ARStarPointerWrapperView: View {
    @StateObject private var locationManager = LocationHeadingManager()
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack(alignment: .top) {
            ARStarPointerView(headingManager: locationManager, errorMessage: $errorMessage)
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading) {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding()
                }
                
                if let heading = locationManager.heading {
                    Text("Heading: \(Int(heading.trueHeading))°")
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
                
                if let location = locationManager.location {
                    Text(String(format: "Lat: %.4f, Lon: %.4f",
                              location.coordinate.latitude,
                              location.coordinate.longitude))
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}
