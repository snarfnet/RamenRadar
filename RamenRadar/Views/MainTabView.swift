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

// MARK: - Ranking View
struct RankingView: View {
    struct RankEntry: Identifiable {
        let id = UUID()
        let rank: Int
        let type: SoupType
        let score: Int
        let label: String
    }

    private let entries: [RankEntry] = [
        RankEntry(rank: 1, type: .tonkotsu, score: 98, label: "濃厚クリーミーで大人気"),
        RankEntry(rank: 2, type: .shoyu,    score: 93, label: "老舗定番、万人受け"),
        RankEntry(rank: 3, type: .tsukemen, score: 89, label: "濃縮スープがクセになる"),
        RankEntry(rank: 4, type: .miso,     score: 85, label: "冬に絶大な人気"),
        RankEntry(rank: 5, type: .jiro,     score: 82, label: "ボリューム系の帝王"),
        RankEntry(rank: 6, type: .tantan,   score: 76, label: "スパイシー好きに刺さる"),
        RankEntry(rank: 7, type: .shio,     score: 71, label: "あっさり派の定番"),
        RankEntry(rank: 8, type: .other,    score: 64, label: "個性派ラーメン"),
    ]

    var body: some View {
        ZStack {
            AppTheme.darkNavy.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("🏆 スープ別人気ランキング")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 12)

                    ForEach(entries) { entry in
                        HStack(spacing: 12) {
                            Text("\(entry.rank)")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(entry.rank <= 3 ? AppTheme.neonRed : AppTheme.textSecondary)
                                .frame(width: 28, alignment: .center)

                            Text(entry.type.icon)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.type.rawValue)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                                Text(entry.label)
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.textSecondary)
                            }

                            Spacer()

                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppTheme.cardBackgroundLight)
                                    .frame(width: 70, height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(entry.rank <= 3 ? AppTheme.neonRed : AppTheme.neonBlue)
                                    .frame(width: 70 * CGFloat(entry.score) / 100, height: 8)
                            }

                            Text("\(entry.score)")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(AppTheme.neonYellow)
                                .frame(width: 32, alignment: .trailing)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppTheme.cardBackground)
                        .overlay(
                            Rectangle()
                                .fill(AppTheme.darkNavy)
                                .frame(height: 1),
                            alignment: .bottom
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Diagnosis View
struct DiagnosisView: View {
    private let questions: [(String, [String])] = [
        ("どんな濃さが好き？", ["あっさり", "ちょうどいい", "濃厚"]),
        ("スープの味は？", ["塩・醤油系", "味噌系", "豚骨系"]),
        ("ボリュームは？", ["少なめ", "普通", "がっつり"]),
    ]

    @State private var answers: [Int] = [-1, -1, -1]
    @State private var result: SoupType? = nil

    private func diagnose() {
        let rich = answers[0]
        let flavor = answers[1]
        let volume = answers[2]

        if volume == 2 && rich == 2 { result = .jiro; return }
        if flavor == 2 { result = .tonkotsu; return }
        if flavor == 1 { result = .miso; return }
        if rich == 0 && flavor == 0 { result = .shio; return }
        if rich == 2 { result = .tsukemen; return }
        result = .shoyu
    }

    var body: some View {
        ZStack {
            AppTheme.darkNavy.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("🌶️ あなたの味タイプ診断")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.top, 20)

                    ForEach(questions.indices, id: \.self) { qi in
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Q\(qi + 1). \(questions[qi].0)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)

                            HStack(spacing: 8) {
                                ForEach(questions[qi].1.indices, id: \.self) { ai in
                                    Button {
                                        answers[qi] = ai
                                        result = nil
                                    } label: {
                                        Text(questions[qi].1[ai])
                                            .font(.system(size: 13, weight: .medium))
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .frame(maxWidth: .infinity)
                                            .background(answers[qi] == ai ? AppTheme.neonRed.opacity(0.25) : AppTheme.cardBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(answers[qi] == ai ? AppTheme.neonRed : AppTheme.cardBackgroundLight, lineWidth: 1.5)
                                            )
                                            .foregroundColor(answers[qi] == ai ? AppTheme.neonRed : AppTheme.textSecondary)
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }

                    Button {
                        diagnose()
                    } label: {
                        Text("診断する")
                            .font(.system(size: 15, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(answers.allSatisfy { $0 >= 0 } ? AppTheme.neonRed : AppTheme.cardBackgroundLight)
                            .foregroundColor(AppTheme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(answers.contains(-1))

                    if let r = result {
                        VStack(spacing: 8) {
                            Text("あなたのタイプは…")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textSecondary)
                            Text("\(r.icon) \(r.rawValue)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(AppTheme.neonYellow)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }
}
