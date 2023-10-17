import SwiftUI
import WebKit

let apiKey = "Your API Key"

struct ContentView: View {
    @State private var origin: String = ""
    @State private var destination: String = ""
    @State private var isNavigationActive: Bool = false
    @State private var originResult: Location?
    @State private var destResult: Location?
    @State private var isRouteAvailable: Bool = true
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Adresse de départ", text: $origin)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                TextField("Adresse d'arrivée", text: $destination)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                NavigationLink(destination: ResultView(originResult: originResult, destResult: destResult, isRouteAvailable: isRouteAvailable),
                               isActive: $isNavigationActive) {
                    EmptyView()
                }
                Button(action: {
                    getDirections(origin: origin, destination: destination)
                }) {
                    Text("Search")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }

    func getDirections(origin: String, destination: String) {
        let origin = origin.replacingOccurrences(of: " ", with: "+")
        let destination = destination.replacingOccurrences(of: " ", with: "+")

        let urlStr = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&key=\(apiKey)"

        if let url = URL(string: urlStr) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let directionsResponse = try decoder.decode(DirectionsResponse.self, from: data)
                        if let route = directionsResponse.routes.first,
                           let leg = route.legs.first {
                            let startLocation = leg.start_location
                            let endLocation = leg.end_location
                            originResult = Location(lat: startLocation.lat, lng: startLocation.lng)
                            destResult = Location(lat: endLocation.lat, lng: endLocation.lng)
                            isRouteAvailable = true
                        } else {
                            isRouteAvailable = false
                        }
                    } catch {
                        print("Erreur : \(error.localizedDescription)")
                    }
                } else if let error = error {
                    print("Erreur : \(error.localizedDescription)")
                }
                isNavigationActive = true
            }.resume()
        }
    }
}

struct ResultView: View {
    var originResult: Location?
    var destResult: Location?
    var isRouteAvailable: Bool

    var body: some View {
        if isRouteAvailable {
            if let destLat = destResult?.lat, let destLng = destResult?.lng {
                if let originLat = originResult?.lat, let originLng = originResult?.lng {
                    let urlString = "https://www.google.com/maps/dir/?api=1&origin=\(originLat),\(originLng)&destination=\(destLat),\(destLng)&travelmode=walking"
                    MapView(url: URL(string: urlString)!)
                        .navigationBarTitle("Itinéraire")
                } else {
                    Text("Coordonnées de départ non valides")
                }
            } else {
                Text("Coordonnées de destination non valides")
            }
        } else {
            Text("Aucun itinéraire n'a été trouvé")
                .font(.footnote)
                .padding()
        }
    }
}

struct MapView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct DirectionsResponse: Decodable {
    let routes: [Route]
}

struct Route: Decodable {
    let legs: [Leg]
}

struct Leg: Decodable {
    let start_location: Location
    let end_location: Location
}

struct Location: Decodable {
    let lat: Double
    let lng: Double
}
