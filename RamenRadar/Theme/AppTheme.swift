import SwiftUI

enum AppTheme {
    static let ink = Color(hex: "090706")
    static let charcoal = Color(hex: "15100D")
    static let card = Color(hex: "221811")
    static let cardLight = Color(hex: "312118")

    static let lantern = Color(hex: "E63820")
    static let chili = Color(hex: "FF6B2A")
    static let broth = Color(hex: "D99A3D")
    static let noodle = Color(hex: "F5D89D")
    static let teal = Color(hex: "33D6C2")

    static let textPrimary = Color(hex: "FFF7E8")
    static let textSecondary = Color(hex: "BFAE9C")
    static let border = Color.white.opacity(0.08)

    static let congestionLow = teal
    static let congestionMid = broth
    static let congestionHigh = lantern

    static let backgroundGradient = LinearGradient(
        colors: [ink, Color(hex: "160A06"), charcoal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
