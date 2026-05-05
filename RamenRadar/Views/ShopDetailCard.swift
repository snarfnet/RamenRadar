import SwiftUI
import CoreLocation

struct ShopDetailCard: View {
    let shop: RamenShop
    let onDismiss: () -> Void

    @State private var sonarScale: CGFloat = 0.5
    @State private var sonarOpacity: Double = 1.0
    @State private var showMapSheet = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Drag handle
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppTheme.textSecondary.opacity(0.4))
                        .frame(width: 40, height: 5)
                        .padding(.top, 12)

                    // Sonar pulse effect at top
                    ZStack {
                        // Ramen image placeholder
                        ZStack {
                            AppTheme.cardBackgroundLight
                            Text(shop.soupType.icon)
                                .font(.system(size: 64))
                        }
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 0))

                        // Sonar ripple
                        Circle()
                            .stroke(AppTheme.neonRed.opacity(sonarOpacity * 0.5), lineWidth: 2)
                            .scaleEffect(sonarScale)
                            .frame(width: 60, height: 60)
                    }

                    // Shop info
                    VStack(spacing: 12) {
                        // Name & rating
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(shop.name)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                Text(shop.soupType.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.neonYellow)
                            }

                            Spacer()

                            // Rating badge
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                Text(String(format: "%.1f", shop.rating))
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(AppTheme.neonYellow)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(AppTheme.neonYellow.opacity(0.15))
                            )
                        }

                        // Stats row
                        HStack(spacing: 16) {
                            statItem(icon: "figure.walk", value: "徒歩\(shop.walkMinutes)分", color: AppTheme.textPrimary)
                            statItem(icon: "yensign.circle", value: shop.priceRange.rawValue, color: AppTheme.textPrimary)
                            if shop.isOpenLateNight {
                                statItem(icon: "moon.fill", value: "深夜OK", color: AppTheme.neonYellow)
                            }
                        }

                        // Congestion bar
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("混雑度")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary)
                                Spacer()
                                Text("\(shop.congestionLabel.icon) \(shop.congestionLabel.text)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(congestionColor)
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(AppTheme.cardBackgroundLight)
                                        .frame(height: 8)

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [AppTheme.neonBlue, AppTheme.neonYellow, AppTheme.neonRed],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * shop.congestion, height: 8)
                                }
                            }
                            .frame(height: 8)
                        }

                        // Navigate button
                        Button {
                            showMapSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "location.fill")
                                Text("ここに行く（徒歩\(shop.walkMinutes)分）")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.neonRed)
                                    .shadow(color: AppTheme.neonRed.opacity(0.4), radius: 8)
                            )
                        }
                        .confirmationDialog("マップアプリを選択", isPresented: $showMapSheet, titleVisibility: .visible) {
                            Button("Apple マップ") { openAppleMaps() }
                            Button("Google マップ") { openGoogleMaps() }
                            Button("キャンセル", role: .cancel) {}
                        }
                    }
                    .padding(20)
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AppTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(AppTheme.neonRed.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                sonarScale = 3.0
                sonarOpacity = 0
            }
        }
    }

    private func statItem(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(value)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(color)
    }

    private var congestionColor: Color {
        if shop.congestion > 0.7 { return AppTheme.neonRed }
        if shop.congestion > 0.4 { return AppTheme.neonYellow }
        return AppTheme.neonBlue
    }

    private func openAppleMaps() {
        let lat = shop.coordinate.latitude
        let lng = shop.coordinate.longitude
        let url = URL(string: "https://maps.apple.com/?daddr=\(lat),\(lng)&dirflg=w")!
        UIApplication.shared.open(url)
    }

    private func openGoogleMaps() {
        let lat = shop.coordinate.latitude
        let lng = shop.coordinate.longitude
        let url = URL(string: "comgooglemaps://?daddr=\(lat),\(lng)&directionsmode=walking")!
        let webUrl = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(lat),\(lng)&travelmode=walking")!

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            UIApplication.shared.open(webUrl)
        }
    }
}
