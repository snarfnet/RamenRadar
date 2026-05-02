import Foundation
import CoreLocation

struct RamenShop: Identifiable {
    let id = UUID()
    let name: String
    let nameEn: String
    let soupType: SoupType
    let rating: Double
    let congestion: Double // 0.0 - 1.0
    let coordinate: CLLocationCoordinate2D
    let distance: Double // meters
    let walkMinutes: Int
    let isOpenLateNight: Bool
    let priceRange: PriceRange
    let imageURL: String?

    var congestionLabel: CongestionLabel {
        if congestion > 0.7 && rating > 4.0 {
            return .worthWaiting
        } else if congestion > 0.7 {
            return .avoidNow
        } else if rating > 4.0 {
            return .chanceNow
        } else {
            return .normal
        }
    }

    var dotColor: DotColor {
        if rating >= 4.0 { return .popular }
        if soupType == .shio || soupType == .shoyu { return .light }
        if isOpenLateNight { return .lateNight }
        return .popular
    }
}

enum SoupType: String, CaseIterable {
    case tonkotsu = "豚骨"
    case shoyu = "醤油"
    case miso = "味噌"
    case shio = "塩"
    case jiro = "二郎系"
    case tsukemen = "つけ麺"
    case tantan = "担々麺"
    case other = "その他"

    var icon: String {
        switch self {
        case .tonkotsu: return "🍖"
        case .shoyu: return "🫘"
        case .miso: return "🫕"
        case .shio: return "🧂"
        case .jiro: return "💪"
        case .tsukemen: return "🥢"
        case .tantan: return "🌶️"
        case .other: return "🍜"
        }
    }
}

enum PriceRange: String, CaseIterable {
    case budget = "~800円"
    case standard = "800~1200円"
    case premium = "1200円~"
}

enum CongestionLabel {
    case worthWaiting  // 高混雑 + 高評価
    case avoidNow      // 高混雑 + 普通評価
    case chanceNow     // 低混雑 + 高評価
    case normal        // 低混雑 + 普通評価

    var text: String {
        switch self {
        case .worthWaiting: return "並ぶ価値あり"
        case .avoidNow: return "今は避けろ"
        case .chanceNow: return "今がチャンス"
        case .normal: return "普通に入れる"
        }
    }

    var icon: String {
        switch self {
        case .worthWaiting: return "🔥"
        case .avoidNow: return "⏳"
        case .chanceNow: return "✨"
        case .normal: return "👍"
        }
    }
}

enum DotColor {
    case popular    // Red - popular shops
    case light      // Blue - light flavor
    case lateNight  // Yellow - late night
}
