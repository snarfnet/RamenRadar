import SwiftUI

struct FilterView: View {
    @ObservedObject var viewModel: RadarViewModel
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.66)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppTheme.textSecondary.opacity(0.45))
                            .frame(width: 42, height: 5)
                        Spacer()
                    }

                    Text("条件を絞り込む")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)

                    filterSection(title: "スープ") {
                        FlowLayout(spacing: 8) {
                            ForEach(SoupType.allCases, id: \.self) { soup in
                                chipButton(
                                    icon: soup.icon,
                                    text: soup.rawValue,
                                    isSelected: viewModel.selectedSoupTypes.contains(soup)
                                ) {
                                    if viewModel.selectedSoupTypes.contains(soup) {
                                        viewModel.selectedSoupTypes.remove(soup)
                                    } else {
                                        viewModel.selectedSoupTypes.insert(soup)
                                    }
                                }
                            }
                        }
                    }

                    filterSection(title: "価格帯") {
                        HStack(spacing: 8) {
                            ForEach(PriceRange.allCases, id: \.self) { price in
                                chipButton(icon: "yensign", text: price.rawValue, isSelected: viewModel.selectedPriceRange == price) {
                                    viewModel.selectedPriceRange = viewModel.selectedPriceRange == price ? nil : price
                                }
                            }
                        }
                    }

                    VStack(spacing: 12) {
                        toggleRow(icon: "moon.fill", text: "深夜営業のみ", isOn: $viewModel.lateNightOnly)
                        toggleRow(icon: "person.2.slash.fill", text: "空いている店を優先", isOn: $viewModel.lowCongestionFirst)
                    }

                    Button {
                        viewModel.selectedSoupTypes.removeAll()
                        viewModel.selectedPriceRange = nil
                        viewModel.lateNightOnly = false
                        viewModel.lowCongestionFirst = false
                    } label: {
                        Text("リセット")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border, lineWidth: 1))
                    }
                }
                .padding(20)
                .padding(.bottom, 28)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(AppTheme.border, lineWidth: 1))
            }
            .padding(.horizontal, 16)
        }
    }

    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .black))
                .foregroundColor(AppTheme.noodle)
            content()
        }
    }

    private func chipButton(icon: String, text: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(text, systemImage: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(isSelected ? AppTheme.lantern : AppTheme.cardLight)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? AppTheme.chili.opacity(0.7) : AppTheme.border, lineWidth: 1))
        }
    }

    private func toggleRow(icon: String, text: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppTheme.noodle)
                .frame(width: 28)
            Text(text)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            Toggle("", isOn: isOn)
                .tint(AppTheme.lantern)
                .labelsHidden()
        }
        .padding(12)
        .background(AppTheme.cardLight.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}
