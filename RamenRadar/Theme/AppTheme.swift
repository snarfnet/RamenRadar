import SwiftUI

enum AppTheme {
    // Backgrounds
    static let darkNavy = Color(hex: "0D1117")
    static let cardBackground = Color(hex: "161B22")
    static let cardBackgroundLight = Color(hex: "1C2128")

    // Accents
    static let neonRed = Color(hex: "E63946")
    static let neonYellow = Color(hex: "FFD60A")
    static let neonBlue = Color(hex: "4CC9F0")

    // Text
    static let textPrimary = Color(hex: "F0F0F0")
    static let textSecondary = Color(hex: "8B949E")

    // Radar
    static let radarGreen = Color(hex: "E63946") // Red themed radar
    static let radarLine = Color(hex: "E63946").opacity(0.8)
    static let radarGrid = Color(hex: "E63946").opacity(0.15)
    static let radarGlow = Color(hex: "E63946").opacity(0.3)

    // Congestion
    static let congestionLow = Color(hex: "4CC9F0")
    static let congestionMid = Color(hex: "FFD60A")
    static let congestionHigh = Color(hex: "E63946")
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
