import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            BannerAdView(adUnitID: "ca-app-pub-9404799280370656/1176058909")
                .frame(height: 50)
                .background(AppTheme.ink)

            ZStack(alignment: .bottom) {
                AppTheme.backgroundGradient.ignoresSafeArea()

                TabView(selection: $selectedTab) {
                    RadarView().tag(0)
                    RankingView().tag(1)
                    DiagnosisView().tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 0) {
                    tabButton(icon: "scope", label: "レーダー", tag: 0)
                    tabButton(icon: "chart.bar.fill", label: "ランキング", tag: 1)
                    tabButton(icon: "wand.and.stars", label: "味診断", tag: 2)
                }
                .padding(.horizontal, 8)
                .padding(.top, 10)
                .padding(.bottom, 10)
                .background(.ultraThinMaterial)
                .overlay(Rectangle().fill(AppTheme.lantern.opacity(0.24)).frame(height: 1), alignment: .top)
            }

            BannerAdView(adUnitID: "ca-app-pub-9404799280370656/5044211211")
                .frame(height: 50)
                .background(AppTheme.ink)
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
                    .font(.system(size: 19, weight: .bold))
                Text(label)
                    .font(.system(size: 10, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(selectedTab == tag ? AppTheme.noodle : AppTheme.textSecondary)
            .frame(maxWidth: .infinity)
        }
    }
}

struct RankingView: View {
    struct RankEntry: Identifiable {
        let id = UUID()
        let rank: Int
        let type: SoupType
        let score: Int
        let label: String
    }

    private let entries: [RankEntry] = [
        RankEntry(rank: 1, type: .tsukemen, score: 98, label: "濃厚スープで満足度が高い"),
        RankEntry(rank: 2, type: .tonkotsu, score: 94, label: "夜でも食べたくなる定番"),
        RankEntry(rank: 3, type: .shio, score: 90, label: "軽く食べたい日に強い"),
        RankEntry(rank: 4, type: .miso, score: 86, label: "寒い日と相性がいい"),
        RankEntry(rank: 5, type: .jiro, score: 82, label: "がっつり派から支持"),
        RankEntry(rank: 6, type: .tantan, score: 78, label: "辛さで気分を上げたい時に"),
        RankEntry(rank: 7, type: .shoyu, score: 74, label: "王道で外しにくい"),
        RankEntry(rank: 8, type: .other, score: 68, label: "新しい一杯に出会える")
    ]

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    hero(title: "今夜の人気スープ", subtitle: "近くで選ばれやすい味を、満足度順にチェック。")

                    ForEach(entries) { entry in
                        rankRow(entry)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 118)
            }
        }
    }

    private func hero(title: String, subtitle: String) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image("ramen-ranking")
                .resizable()
                .scaledToFill()
                .frame(height: 210)
                .clipped()
            LinearGradient(colors: [.clear, AppTheme.ink.opacity(0.88)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(AppTheme.border, lineWidth: 1))
    }

    private func rankRow(_ entry: RankEntry) -> some View {
        HStack(spacing: 13) {
            Text("\(entry.rank)")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(entry.rank <= 3 ? AppTheme.noodle : AppTheme.textSecondary)
                .frame(width: 34, height: 44)
                .background(AppTheme.cardLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Image(systemName: entry.type.icon)
                .foregroundColor(AppTheme.chili)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.type.rawValue)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Text(entry.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text("\(entry.score)")
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundColor(AppTheme.broth)
                Capsule()
                    .fill(entry.rank <= 3 ? AppTheme.lantern : AppTheme.teal)
                    .frame(width: 72 * CGFloat(entry.score) / 100, height: 7)
            }
            .frame(width: 78, alignment: .trailing)
        }
        .padding(14)
        .background(AppTheme.card.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppTheme.border, lineWidth: 1))
    }
}

struct DiagnosisView: View {
    private let questions: [(String, [String])] = [
        ("今日はどんな濃さがいい？", ["あっさり", "ほどよい", "濃厚"]),
        ("香りで選ぶなら？", ["醤油・塩", "味噌", "豚骨"]),
        ("ボリュームは？", ["軽め", "普通", "がっつり"])
    ]

    @State private var answers: [Int] = [-1, -1, -1]
    @State private var result: SoupType? = nil

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    hero

                    ForEach(questions.indices, id: \.self) { qi in
                        questionCard(index: qi)
                    }

                    Button {
                        diagnose()
                    } label: {
                        Text("おすすめの一杯を診断")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(answers.allSatisfy { $0 >= 0 } ? AppTheme.lantern : AppTheme.cardLight)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(answers.contains(-1))

                    if let result {
                        resultCard(result)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 118)
            }
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            Image("ramen-ranking")
                .resizable()
                .scaledToFill()
                .frame(height: 210)
                .clipped()
            LinearGradient(colors: [.clear, AppTheme.ink.opacity(0.9)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 6) {
                Text("今日の味診断")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Text("気分に合うスープを3問で選びます。")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(AppTheme.border, lineWidth: 1))
    }

    private func questionCard(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Q\(index + 1). \(questions[index].0)")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)

            HStack(spacing: 8) {
                ForEach(questions[index].1.indices, id: \.self) { ai in
                    Button {
                        answers[index] = ai
                        result = nil
                    } label: {
                        Text(questions[index].1[ai])
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(answers[index] == ai ? .white : AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(answers[index] == ai ? AppTheme.lantern : AppTheme.cardLight)
                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.card.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppTheme.border, lineWidth: 1))
    }

    private func resultCard(_ soup: SoupType) -> some View {
        VStack(spacing: 10) {
            Image(systemName: soup.icon)
                .font(.system(size: 40, weight: .black))
                .foregroundColor(AppTheme.noodle)
            Text("今日は \(soup.rawValue)")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            Text(resultMessage(soup))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(AppTheme.card.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(AppTheme.lantern.opacity(0.26), lineWidth: 1))
    }

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

    private func resultMessage(_ soup: SoupType) -> String {
        switch soup {
        case .tonkotsu: return "濃厚で満足感のある一杯が合いそうです。"
        case .shoyu: return "香りの良い王道スープで気分を整えましょう。"
        case .miso: return "熱々の味噌で、しっかり温まる日です。"
        case .shio: return "軽く澄んだ味で、すっきり食べられます。"
        case .jiro: return "今日は迷わずボリューム重視でいきましょう。"
        case .tsukemen: return "濃いめのスープをじっくり楽しむ気分です。"
        case .tantan: return "辛さと香ばしさで気分を上げたい日です。"
        case .other: return "定番から少し外れた一杯が楽しめそうです。"
        }
    }
}
