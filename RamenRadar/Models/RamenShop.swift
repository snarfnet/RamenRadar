import Foundation
import CoreLocation

struct RamenShop: Identifiable {
    let id = UUID()
    let name: String
    let nameEn: String
    let soupType: SoupType
    let rating: Double
    let congestion: Double
    let coordinate: CLLocationCoordinate2D
    let distance: Double
    let walkMinutes: Int
    let isOpenLateNight: Bool
    let priceRange: PriceRange
    let note: String

    var congestionLabel: CongestionLabel {
        if congestion > 0.72 && rating > 4.2 {
            return .worthWaiting
        } else if congestion > 0.72 {
            return .avoidNow
        } else if rating > 4.1 {
            return .chanceNow
        } else {
            return .normal
        }
    }

    var dotColor: DotColor {
        if congestion > 0.72 { return .hot }
        if isOpenLateNight { return .lateNight }
        if soupType == .shio || soupType == .shoyu { return .light }
        return .standard
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
    case other = "個性派"

    var icon: String {
        switch self {
        case .tonkotsu: return "bowl.fill"
        case .shoyu: return "drop.fill"
        case .miso: return "flame.fill"
        case .shio: return "sparkles"
        case .jiro: return "mountain.2.fill"
        case .tsukemen: return "takeoutbag.and.cup.and.straw.fill"
        case .tantan: return "bolt.fill"
        case .other: return "star.fill"
        }
    }
}

enum PriceRange: String, CaseIterable {
    case budget = "~800円"
    case standard = "800~1200円"
    case premium = "1200円~"
}

enum CongestionLabel {
    case worthWaiting
    case avoidNow
    case chanceNow
    case normal

    var text: String {
        switch self {
        case .worthWaiting: return "並ぶ価値あり"
        case .avoidNow: return "今は混み気味"
        case .chanceNow: return "今が狙い目"
        case .normal: return "入りやすい"
        }
    }

    var icon: String {
        switch self {
        case .worthWaiting: return "flame.fill"
        case .avoidNow: return "clock.badge.exclamationmark"
        case .chanceNow: return "checkmark.seal.fill"
        case .normal: return "person.2.fill"
        }
    }
}

enum DotColor {
    case hot
    case light
    case lateNight
    case standard
}
