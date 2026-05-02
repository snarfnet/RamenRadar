import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Top banner ad
            BannerAdView(adUnitID: "ca-app-pub-9404799280370656/1176058909")
                .frame(height: 50)
                .background(AppTheme.cardBackground)

            ZStack(alignment: .bottom) {
                AppTheme.darkNavy.ignoresSafeArea()

                TabView(selection: $selectedTab) {
                    RadarView()
                        .tag(0)

                    RankingView()
                        .tag(1)

                    DiagnosisView()
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Custom tab bar
                HStack(spacing: 0) {
                    tabButton(icon: "antenna.radiowaves.left.and.right", label: "レーダー", tag: 0)
                    tabButton(icon: "chart.bar.fill", label: "ランキング", tag: 1)
                    tabButton(icon: "questionmark.circle.fill", label: "味診断", tag: 2)
                }
                .padding(.horizontal, 8)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(
                    AppTheme.cardBackground
                        .overlay(
                            Rectangle()
                                .fill(AppTheme.neonRed.opacity(0.3))
                                .frame(height: 1),
                            alignment: .top
                        )
                )
            }

            // Bottom banner ad
            BannerAdView(adUnitID: "ca-app-pub-9404799280370656/5044211211")
                .frame(height: 50)
                .background(AppTheme.cardBackground)
        }
        .ignoresSafeArea(.keyboard)
    }

    private func tabButton(icon: String, label: String, tag: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tag
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(selectedTab == tag ? AppTheme.neonRed : AppTheme.textSecondary)
            .frame(maxWidth: .infinity)
        }
    }
}

// Placeholder views
struct RankingView: View {
    var body: some View {
        ZStack {
            AppTheme.darkNavy.ignoresSafeArea()
            Text("ランキング")
                .foregroundColor(AppTheme.textPrimary)
                .font(.title2)
        }
    }
}

struct DiagnosisView: View {
    var body: some View {
        ZStack {
            AppTheme.darkNavy.ignoresSafeArea()
            Text("味診断")
                .foregroundColor(AppTheme.textPrimary)
                .font(.title2)
        }
    }
}
