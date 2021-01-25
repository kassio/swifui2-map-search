import Foundation
import SwiftUI
import MapKit

class LocationManager: NSObject, ObservableObject {
    private let locationManager =  CLLocationManager()

    @Published var region = MKCoordinateRegion()

    override init() {
        super.init()

        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        locations.last.map {
            let center = CLLocationCoordinate2D(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
}

struct LandmarkInfoView: View {
    @Binding var landmark: Landmark
    var closeAction: () -> Void

    var body: some View {
        VStack {
            VStack {
                Text(landmark.name).font(.title2).padding(.bottom, 8)
                Text(landmark.locality).font(.body)
                Text(landmark.subLocality).font(.caption)
                Text(landmark.country).font(.caption2)
            }
            .padding(.bottom)
            VStack {
                Text("(\(landmark.latitude), \(landmark.longitude))")
                    .font(.caption)
            }
            .padding(.bottom)

            Button("close", action: closeAction)
        }
        .padding()
        .frame(width: UIScreen.main.bounds.width - 30)
        .background(Color(.systemBackground))
        .cornerRadius(15)
    }
}

struct MapViewDetails<Content: View>: View {
    @Binding var landmark: Landmark?
    let content: Content

    private var unwrappedLandmark: Binding<Landmark> {
        Binding(
            get: { landmark! },
            set: { landmark = $0 }
        )
    }

    init(_ landmark: Binding<Landmark?>, @ViewBuilder content: () -> Content) {
        self._landmark = landmark
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            content
            if landmark != nil {
                LandmarkInfoView(landmark: unwrappedLandmark) {
                    landmark = nil
                }
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject private var locationManager = LocationManager()
    @State private var landmarks: [Landmark] = []
    @State private var isPresentingLandmark: Landmark?
    @State private var query: String = ""

    var body: some View {
        MapViewDetails($isPresentingLandmark) {
            ZStack(alignment: .topLeading) {
                Map(
                    coordinateRegion: $locationManager.region,
                    interactionModes: .all,
                    showsUserLocation: true,
                    annotationItems: landmarks,
                    annotationContent: { landmark in
                        MapAnnotation(coordinate: landmark.coordinate) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                                .background(Color(.systemBackground).clipShape(Circle()))
                                .onTapGesture  { isPresentingLandmark = landmark }
                        }
                    }
                )

                TextField("query", text: $query, onCommit: getLandmarks)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.top, 60)
                    .padding(.horizontal)
            }
            .edgesIgnoringSafeArea(.all)
        }
    }

    private func getLandmarks() {
        let request =  MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        let search = MKLocalSearch(request: request)
        search.start(completionHandler: { (response, error) in
            if let response = response {
                landmarks = response.mapItems.map {
                    Landmark(placemark: $0.placemark)
                }
            }
        })
    }
}

struct Landmark: Identifiable {
    let placemark: MKPlacemark

    var id: UUID = UUID()
    var name: String { placemark.name ?? "" }
    var country: String { placemark.country ?? "" }
    var postalCode: String { placemark.postalCode ?? "" }
    var locality: String { placemark.locality ?? "" }
    var subLocality: String { placemark.subLocality ?? "" }
    var latitude: Double { placemark.coordinate.latitude }
    var longitude: Double { placemark.coordinate.longitude }

    var coordinate: CLLocationCoordinate2D { placemark.coordinate }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
