import SwiftUI
import CoreLocation

struct RadarView: View {
    @StateObject private var viewModel = RadarViewModel()
    @State private var scanAngle: Double = 0
    @State private var showDetail: RamenShop? = nil
    @State private var showFilter = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            Image("ramen-hero")
                .resizable()
                .scaledToFill()
                .frame(height: 260)
                .clipped()
                .overlay(
                    LinearGradient(colors: [.black.opacity(0.05), AppTheme.ink.opacity(0.92)], startPoint: .top, endPoint: .bottom)
                )
                .ignoresSafeArea(edges: .top)
                .frame(maxHeight: .infinity, alignment: .top)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerView
                    hotShopsCarousel
                    radarPanel
                    quickTips
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 118)
            }

            if let shop = showDetail {
                ShopDetailCard(shop: shop) {
                    withAnimation(.spring(response: 0.3)) {
                        showDetail = nil
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
            }

            if showFilter {
                FilterView(viewModel: viewModel) {
                    withAnimation(.spring(response: 0.3)) {
                        showFilter = false
                    }
                }
                .transition(.move(edge: .bottom))
                .zIndex(11)
            }
        }
        .onAppear {
            startScanAnimation()
        }
    }

    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("麺ナビ")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .shadow(color: AppTheme.lantern.opacity(0.8), radius: 14)
                Text(viewModel.timeSlotMessage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.noodle)
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3)) {
                    showFilter.toggle()
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.noodle)
                    .frame(width: 46, height: 46)
                    .background(AppTheme.card.opacity(0.86))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
            }
        }
        .padding(.top, 18)
    }

    private var hotShopsCarousel: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(icon: "flame.fill", title: "今すぐ行きたい店")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.hotShops.prefix(5)) { shop in
                        hotShopCard(shop)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    showDetail = shop
                                }
                            }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func hotShopCard(_ shop: RamenShop) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: shop.soupType.icon)
                    .foregroundColor(AppTheme.noodle)
                    .frame(width: 34, height: 34)
                    .background(AppTheme.lantern.opacity(0.22))
                    .clipShape(Circle())
                Spacer()
                Label("\(shop.walkMinutes)分", systemImage: "figure.walk")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Text(shop.name)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)

            Text("\(shop.soupType.rawValue) / \(shop.priceRange.rawValue)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)

            Label(shop.congestionLabel.text, systemImage: shop.congestionLabel.icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(congestionColor(shop))
        }
        .padding(14)
        .frame(width: 190, alignment: .leading)
        .background(cardBackground)
    }

    private var radarPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionTitle(icon: "scope", title: "近くの一杯レーダー")
                Spacer()
                Text("\(viewModel.filteredShops.count)件")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundColor(AppTheme.broth)
            }

            radarCircle
                .padding(.horizontal, 8)

            Text("点をタップすると、混雑・徒歩時間・味のタイプを確認できます。")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(16)
        .background(cardBackground)
    }

    private var radarCircle: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = size / 2 - 12

            ZStack {
                Image("ramen-radar")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .opacity(0.28)

                ForEach(1..<4) { i in
                    Circle()
                        .stroke(AppTheme.lantern.opacity(0.18), lineWidth: 1)
                        .frame(width: radius * 2 * CGFloat(i) / 3, height: radius * 2 * CGFloat(i) / 3)
                }

                Path { path in
                    path.move(to: CGPoint(x: center.x, y: center.y - radius))
                    path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
                    path.move(to: CGPoint(x: center.x - radius, y: center.y))
                    path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
                }
                .stroke(AppTheme.noodle.opacity(0.18), lineWidth: 0.8)

                AngularGradient(
                    gradient: Gradient(colors: [
                        AppTheme.lantern.opacity(0),
                        AppTheme.lantern.opacity(0.06),
                        AppTheme.chili.opacity(0.28),
                        AppTheme.noodle.opacity(0.34)
                    ]),
                    center: .center,
                    startAngle: .degrees(scanAngle - 48),
                    endAngle: .degrees(scanAngle)
                )
                .mask(Circle().frame(width: radius * 2, height: radius * 2))

                Path { path in
                    path.move(to: center)
                    let endX = center.x + radius * CGFloat(cos(scanAngle * .pi / 180 - .pi / 2))
                    let endY = center.y + radius * CGFloat(sin(scanAngle * .pi / 180 - .pi / 2))
                    path.addLine(to: CGPoint(x: endX, y: endY))
                }
                .stroke(AppTheme.noodle.opacity(0.9), lineWidth: 2)
                .shadow(color: AppTheme.chili, radius: 8)

                ForEach(viewModel.filteredShops) { shop in
                    shopDot(shop: shop, center: center, maxRadius: radius)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                showDetail = shop
                            }
                        }
                }

                Circle()
                    .fill(AppTheme.noodle)
                    .frame(width: 12, height: 12)
                    .shadow(color: AppTheme.noodle, radius: 9)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.noodle.opacity(0.35), lineWidth: 2)
                            .scaleEffect(pulseScale)
                            .opacity(2 - pulseScale)
                    )
                    .position(center)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func shopDot(shop: RamenShop, center: CGPoint, maxRadius: CGFloat) -> some View {
        let normalizedDist = min(shop.distance / 1500, 1.0)
        let dotRadius = maxRadius * CGFloat(normalizedDist)
        let angle = Double(abs(shop.name.hashValue) % 360)
        let x = center.x + dotRadius * CGFloat(cos(angle * .pi / 180 - .pi / 2))
        let y = center.y + dotRadius * CGFloat(sin(angle * .pi / 180 - .pi / 2))
        let color = dotColor(shop)

        return ZStack {
            Circle()
                .fill(color.opacity(0.18))
                .frame(width: shop.congestion > 0.7 ? 42 : 30, height: shop.congestion > 0.7 ? 42 : 30)
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .shadow(color: color, radius: 7)
        }
        .position(x: x, y: y)
    }

    private var quickTips: some View {
        HStack(spacing: 10) {
            miniStat(title: "空き", value: "\(viewModel.shops.filter { $0.congestion < 0.45 }.count)店", color: AppTheme.teal)
            miniStat(title: "深夜", value: "\(viewModel.shops.filter { $0.isOpenLateNight }.count)店", color: AppTheme.noodle)
            miniStat(title: "高評価", value: "\(viewModel.shops.filter { $0.rating >= 4.3 }.count)店", color: AppTheme.lantern)
        }
    }

    private func miniStat(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(cardBackground)
    }

    private func sectionTitle(icon: String, title: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.chili)
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(AppTheme.card.opacity(0.82))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(AppTheme.border, lineWidth: 1))
            .shadow(color: AppTheme.lantern.opacity(0.08), radius: 18, y: 10)
    }

    private func dotColor(_ shop: RamenShop) -> Color {
        switch shop.dotColor {
        case .hot: return AppTheme.lantern
        case .light: return AppTheme.teal
        case .lateNight: return AppTheme.noodle
        case .standard: return AppTheme.broth
        }
    }

    private func congestionColor(_ shop: RamenShop) -> Color {
        if shop.congestion > 0.7 { return AppTheme.lantern }
        if shop.congestion > 0.4 { return AppTheme.broth }
        return AppTheme.teal
    }

    private func startScanAnimation() {
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            scanAngle = 360
        }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.8
        }
    }
}
