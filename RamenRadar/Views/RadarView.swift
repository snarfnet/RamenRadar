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
            AppTheme.darkNavy.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                // Top carousel - now hot shops
                hotShopsCarousel

                Spacer(minLength: 8)

                // Radar
                radarCircle
                    .padding(.horizontal, 20)

                Spacer(minLength: 8)

                // Bottom hint
                Text("タップで詳細 | フィルターで絞り込み")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.bottom, 60)
            }

            // Detail card overlay
            if let shop = showDetail {
                ShopDetailCard(shop: shop) {
                    withAnimation(.spring(response: 0.3)) {
                        showDetail = nil
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
            }

            // Filter sheet
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

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("麺ナビ")
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundColor(AppTheme.neonRed)
                Text(viewModel.timeSlotMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.neonYellow)
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3)) {
                    showFilter.toggle()
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.neonYellow)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(AppTheme.cardBackground)
                            .overlay(Circle().stroke(AppTheme.neonYellow.opacity(0.3), lineWidth: 1))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Hot shops carousel

    private var hotShopsCarousel: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundColor(AppTheme.neonRed)
                    .font(.system(size: 12))
                Text("今うまい店")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.hotShops.prefix(5)) { shop in
                        hotShopCard(shop)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    showDetail = shop
                                }
                            }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 8)
    }

    private func hotShopCard(_ shop: RamenShop) -> some View {
        HStack(spacing: 8) {
            Text(shop.soupType.icon)
                .font(.system(size: 24))

            VStack(alignment: .leading, spacing: 2) {
                Text(shop.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                Text("徒歩\(shop.walkMinutes)分 | \(shop.soupType.rawValue)")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer(minLength: 0)

            Text("\(shop.congestionLabel.icon)")
                .font(.system(size: 16))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: 180)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppTheme.neonRed.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Radar Circle

    private var radarCircle: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = size / 2 - 10

            ZStack {
                // Grid circles
                ForEach(1..<4) { i in
                    Circle()
                        .stroke(AppTheme.radarGrid, lineWidth: 1)
                        .frame(width: radius * 2 * CGFloat(i) / 3, height: radius * 2 * CGFloat(i) / 3)
                }

                // Cross lines
                Path { path in
                    path.move(to: CGPoint(x: center.x, y: center.y - radius))
                    path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
                    path.move(to: CGPoint(x: center.x - radius, y: center.y))
                    path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
                }
                .stroke(AppTheme.radarGrid, lineWidth: 0.5)

                // Distance labels
                ForEach(1..<4) { i in
                    let labelRadius = radius * CGFloat(i) / 3
                    Text("\(i * 5)min")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(AppTheme.textSecondary.opacity(0.6))
                        .position(x: center.x + labelRadius + 2, y: center.y - 8)
                }

                // Scan sweep
                AngularGradient(
                    gradient: Gradient(colors: [
                        AppTheme.neonRed.opacity(0.0),
                        AppTheme.neonRed.opacity(0.0),
                        AppTheme.neonRed.opacity(0.05),
                        AppTheme.neonRed.opacity(0.15),
                        AppTheme.neonRed.opacity(0.3),
                    ]),
                    center: .center,
                    startAngle: .degrees(scanAngle - 60),
                    endAngle: .degrees(scanAngle)
                )
                .mask(
                    Circle()
                        .frame(width: radius * 2, height: radius * 2)
                )

                // Scan line
                Path { path in
                    path.move(to: center)
                    let endX = center.x + radius * CGFloat(cos(scanAngle * .pi / 180 - .pi / 2))
                    let endY = center.y + radius * CGFloat(sin(scanAngle * .pi / 180 - .pi / 2))
                    path.addLine(to: CGPoint(x: endX, y: endY))
                }
                .stroke(
                    AppTheme.neonRed.opacity(0.8),
                    lineWidth: 2
                )
                .shadow(color: AppTheme.neonRed, radius: 4)

                // Shop dots
                ForEach(viewModel.filteredShops) { shop in
                    shopDot(shop: shop, center: center, maxRadius: radius)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                showDetail = shop
                            }
                        }
                }

                // Center dot (you)
                Circle()
                    .fill(AppTheme.neonYellow)
                    .frame(width: 10, height: 10)
                    .shadow(color: AppTheme.neonYellow, radius: 6)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.neonYellow.opacity(0.3), lineWidth: 2)
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
        let normalizedDist = min(shop.distance / 1500, 1.0) // 1500m = max radar range
        let dotRadius = maxRadius * CGFloat(normalizedDist)

        // Random but stable angle based on shop id
        let angle = Double(shop.id.hashValue % 360)
        let x = center.x + dotRadius * CGFloat(cos(angle * .pi / 180 - .pi / 2))
        let y = center.y + dotRadius * CGFloat(sin(angle * .pi / 180 - .pi / 2))

        let dotColor: Color = {
            switch shop.dotColor {
            case .popular: return AppTheme.neonRed
            case .light: return AppTheme.neonBlue
            case .lateNight: return AppTheme.neonYellow
            }
        }()

        let congestionGlow = shop.congestion > 0.7

        return ZStack {
            // Congestion heatmap glow
            if congestionGlow {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [dotColor.opacity(0.3), dotColor.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 20
                        )
                    )
                    .frame(width: 40, height: 40)
            }

            Circle()
                .fill(dotColor)
                .frame(width: 10, height: 10)
                .shadow(color: dotColor, radius: 4)
        }
        .position(x: x, y: y)
    }

    // MARK: - Animation

    private func startScanAnimation() {
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            scanAngle = 360
        }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.8
        }
    }
}
