import CoreLocation
import MapKit
import SwiftUI
import WatchKit

struct WatchRamenView: View {
    @StateObject private var finder = WatchRamenFinder()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.04, blue: 0.03), Color(red: 0.18, green: 0.07, blue: 0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if finder.isShowingResults {
                resultList
            } else {
                cravingButton
            }
        }
    }

    private var cravingButton: some View {
        VStack(spacing: 10) {
            Text("🍜")
                .font(.system(size: 46))

            Text("麺ナビ")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.orange)

            Button {
                finder.findNearbyRamen()
                WKInterfaceDevice.current().play(.click)
            } label: {
                Text("ラーメン\n食べたい！")
                    .font(.system(size: 18, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)

            Text("近くの候補をすぐ表示")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
    }

    private var resultList: some View {
        ScrollView {
            VStack(spacing: 8) {
                HStack {
                    Text("近くの一杯")
                        .font(.system(size: 15, weight: .bold))
                    Spacer()
                    Button {
                        finder.isShowingResults = false
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.orange)
                }

                if finder.isLocating {
                    ProgressView()
                        .tint(.orange)
                    Text("現在地を確認中")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                ForEach(finder.results) { shop in
                    WatchRamenCard(shop: shop)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
        }
    }
}

private struct WatchRamenCard: View {
    let shop: WatchRamenShop

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .top) {
                Text(shop.name)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(2)
                Spacer(minLength: 4)
                Text("\(shop.walkMinutes)分")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.orange)
            }

            HStack(spacing: 6) {
                Label(shop.soup, systemImage: "bowl.fill")
                Label(shop.distanceText, systemImage: "figure.walk")
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)

            Text(shop.note)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.82))
                .lineLimit(2)
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private final class WatchRamenFinder: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var results: [WatchRamenShop] = WatchRamenShop.sample
    @Published var isShowingResults = false
    @Published var isLocating = false

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func findNearbyRamen() {
        isShowingResults = true
        isLocating = true
        results = WatchRamenShop.sample.sorted { $0.walkMinutes < $1.walkMinutes }

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            isLocating = false
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        } else if manager.authorizationStatus != .notDetermined {
            isLocating = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            isLocating = false
            return
        }
        searchNearby(from: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLocating = false
    }

    private func searchNearby(from location: CLLocation) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "ラーメン"
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 1800,
            longitudinalMeters: 1800
        )

        MKLocalSearch(request: request).start { [weak self] response, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLocating = false

                let shops = response?.mapItems.prefix(6).map { item in
                    WatchRamenShop(mapItem: item, from: location)
                } ?? []

                if shops.isEmpty {
                    self.results = WatchRamenShop.sample
                } else {
                    self.results = shops.sorted { $0.walkMinutes < $1.walkMinutes }
                }
            }
        }
    }
}

private struct WatchRamenShop: Identifiable {
    let id = UUID()
    let name: String
    let soup: String
    let distanceText: String
    let walkMinutes: Int
    let note: String

    init(name: String, soup: String, distanceText: String, walkMinutes: Int, note: String) {
        self.name = name
        self.soup = soup
        self.distanceText = distanceText
        self.walkMinutes = walkMinutes
        self.note = note
    }

    init(mapItem: MKMapItem, from location: CLLocation) {
        let shopLocation = mapItem.placemark.location
        let distance = shopLocation.map { location.distance(from: $0) } ?? 0
        let meters = max(Int(distance.rounded()), 50)
        let minutes = max(Int(ceil(Double(meters) / 80.0)), 1)
        let locality = [mapItem.placemark.thoroughfare, mapItem.placemark.locality]
            .compactMap { $0 }
            .joined(separator: " ")

        name = mapItem.name ?? "近くのラーメン店"
        soup = "近場"
        distanceText = meters >= 1000 ? String(format: "%.1fkm", Double(meters) / 1000.0) : "\(meters)m"
        walkMinutes = minutes
        note = locality.isEmpty ? "近くの候補として見つかりました。" : locality
    }

    static let sample: [WatchRamenShop] = [
        .init(name: "麺屋 武蔵", soup: "豚骨", distanceText: "200m", walkMinutes: 3, note: "濃厚スープ。急ぎでも満足しやすい一杯。"),
        .init(name: "六厘舎", soup: "つけ麺", distanceText: "350m", walkMinutes: 5, note: "並ぶ価値あり。太麺でしっかり満腹。"),
        .init(name: "AFURI 東京", soup: "塩", distanceText: "500m", walkMinutes: 7, note: "軽めに食べたい時向き。柑橘が香る。"),
        .init(name: "担々麺 ほおずき", soup: "担々麺", distanceText: "600m", walkMinutes: 8, note: "辛さと香ばしさのバランスが良い。")
    ]
}
