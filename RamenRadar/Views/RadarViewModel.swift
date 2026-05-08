import SwiftUI
import CoreLocation

class RadarViewModel: ObservableObject {
    @Published var shops: [RamenShop] = []
    @Published var hotShops: [RamenShop] = []
    @Published var selectedSoupTypes: Set<SoupType> = []
    @Published var selectedPriceRange: PriceRange? = nil
    @Published var lateNightOnly = false
    @Published var lowCongestionFirst = false

    var filteredShops: [RamenShop] {
        var result = shops

        if !selectedSoupTypes.isEmpty {
            result = result.filter { selectedSoupTypes.contains($0.soupType) }
        }
        if let price = selectedPriceRange {
            result = result.filter { $0.priceRange == price }
        }
        if lateNightOnly {
            result = result.filter { $0.isOpenLateNight }
        }
        if lowCongestionFirst {
            result = result.sorted { $0.congestion < $1.congestion }
        }

        return result
    }

    var timeSlotMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<10: return "朝ラー対応の店を優先表示"
        case 11..<14: return "ランチ回転の速い店をスキャン中"
        case 17..<20: return "夕飯どきの混雑をチェック中"
        case 22..<24, 0..<3: return "深夜営業の店を優先表示"
        default: return "近くのラーメン店をスキャン中"
        }
    }

    init() {
        loadDemoData()
    }

    private func loadDemoData() {
        let base = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)

        shops = [
            RamenShop(name: "麺屋 武蔵", nameEn: "Menya Musashi", soupType: .tonkotsu, rating: 4.5, congestion: 0.85, coordinate: base, distance: 200, walkMinutes: 3, isOpenLateNight: true, priceRange: .standard, note: "濃厚スープと香ばしいチャーシューが強い一杯"),
            RamenShop(name: "一蘭 東京駅店", nameEn: "Ichiran Tokyo", soupType: .tonkotsu, rating: 4.2, congestion: 0.92, coordinate: base, distance: 350, walkMinutes: 5, isOpenLateNight: true, priceRange: .standard, note: "深夜でも安定して食べやすい定番"),
            RamenShop(name: "ソラノイロ", nameEn: "Soranoiro", soupType: .shio, rating: 4.6, congestion: 0.45, coordinate: base, distance: 500, walkMinutes: 7, isOpenLateNight: false, priceRange: .premium, note: "軽めなのに印象が残る上品な塩"),
            RamenShop(name: "六厘舎", nameEn: "Rokurinsha", soupType: .tsukemen, rating: 4.7, congestion: 0.95, coordinate: base, distance: 150, walkMinutes: 2, isOpenLateNight: false, priceRange: .standard, note: "並んでも食べたい濃厚つけ麺"),
            RamenShop(name: "味噌の章", nameEn: "Miso no Sho", soupType: .miso, rating: 4.6, congestion: 0.15, coordinate: base, distance: 1100, walkMinutes: 14, isOpenLateNight: true, priceRange: .premium, note: "寒い日に刺さる香りの強い味噌"),
            RamenShop(name: "二郎 新橋店", nameEn: "Jiro Shimbashi", soupType: .jiro, rating: 4.3, congestion: 0.78, coordinate: base, distance: 1200, walkMinutes: 15, isOpenLateNight: false, priceRange: .budget, note: "がっつり食べたい夜に向く一杯"),
            RamenShop(name: "AFURI 東京", nameEn: "AFURI Tokyo", soupType: .shio, rating: 4.4, congestion: 0.55, coordinate: base, distance: 400, walkMinutes: 5, isOpenLateNight: false, priceRange: .standard, note: "柑橘の香りで軽く食べられる"),
            RamenShop(name: "担々麺 ほおずき", nameEn: "Tantan Hoozuki", soupType: .tantan, rating: 4.1, congestion: 0.2, coordinate: base, distance: 600, walkMinutes: 8, isOpenLateNight: true, priceRange: .standard, note: "辛さと香ばしさのバランスが良い"),
            RamenShop(name: "東京醤油 麺龍", nameEn: "Tokyo Shoyu Ryu", soupType: .shoyu, rating: 3.8, congestion: 0.4, coordinate: base, distance: 900, walkMinutes: 12, isOpenLateNight: false, priceRange: .budget, note: "すっきりした王道醤油"),
            RamenShop(name: "背脂食堂 黒椿", nameEn: "Kurotsubaki", soupType: .other, rating: 4.0, congestion: 0.32, coordinate: base, distance: 760, walkMinutes: 9, isOpenLateNight: true, priceRange: .budget, note: "背脂の甘みが残る個性派")
        ]

        hotShops = shops.sorted { a, b in
            let scoreA = a.rating * (1.0 - a.congestion * 0.28) / max(Double(a.walkMinutes), 1)
            let scoreB = b.rating * (1.0 - b.congestion * 0.28) / max(Double(b.walkMinutes), 1)
            return scoreA > scoreB
        }
    }
}
