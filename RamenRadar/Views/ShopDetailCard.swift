import SwiftUI
import CoreLocation

struct ShopDetailCard: View {
    let shop: RamenShop
    let onDismiss: () -> Void

    @State private var showMapSheet = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.66)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppTheme.textSecondary.opacity(0.45))
                        .frame(width: 42, height: 5)
                        .padding(.top, 12)

                    ZStack(alignment: .bottomLeading) {
                        Image("ramen-hero")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 176)
                            .clipped()

                        LinearGradient(colors: [.clear, .black.opacity(0.78)], startPoint: .top, endPoint: .bottom)

                        VStack(alignment: .leading, spacing: 5) {
                            Label(shop.soupType.rawValue, systemImage: shop.soupType.icon)
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(AppTheme.noodle)
                            Text(shop.name)
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        .padding(18)
                    }
                    .frame(height: 176)

                    VStack(spacing: 16) {
                        HStack(spacing: 10) {
                            metric(icon: "star.fill", value: String(format: "%.1f", shop.rating), label: "評価", color: AppTheme.noodle)
                            metric(icon: "figure.walk", value: "\(shop.walkMinutes)分", label: "徒歩", color: AppTheme.teal)
                            metric(icon: "yensign.circle.fill", value: shop.priceRange.rawValue, label: "価格", color: AppTheme.broth)
                        }

                        Text(shop.note)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 7) {
                            HStack {
                                Text("混雑レベル")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AppTheme.textSecondary)
                                Spacer()
                                Label(shop.congestionLabel.text, systemImage: shop.congestionLabel.icon)
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(congestionColor)
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(AppTheme.cardLight)
                                    Capsule()
                                        .fill(LinearGradient(colors: [AppTheme.teal, AppTheme.broth, AppTheme.lantern], startPoint: .leading, endPoint: .trailing))
                                        .frame(width: geo.size.width * shop.congestion)
                                }
                            }
                            .frame(height: 9)
                        }

                        Button {
                            showMapSheet = true
                        } label: {
                            Label("ここへ行く  徒歩\(shop.walkMinutes)分", systemImage: "location.fill")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(
                                    LinearGradient(colors: [AppTheme.lantern, AppTheme.chili], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                                .shadow(color: AppTheme.lantern.opacity(0.35), radius: 14, y: 8)
                        }
                        .confirmationDialog("マップアプリを選択", isPresented: $showMapSheet, titleVisibility: .visible) {
                            Button("Appleマップ") { openAppleMaps() }
                            Button("Googleマップ") { openGoogleMaps() }
                            Button("キャンセル", role: .cancel) {}
                        }
                    }
                    .padding(18)
                }
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(AppTheme.border, lineWidth: 1))
                .padding(.horizontal, 16)
                .padding(.bottom, 38)
            }
        }
    }

    private func metric(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppTheme.cardLight.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private var congestionColor: Color {
        if shop.congestion > 0.7 { return AppTheme.lantern }
        if shop.congestion > 0.4 { return AppTheme.broth }
        return AppTheme.teal
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
