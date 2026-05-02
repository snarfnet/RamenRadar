import SwiftUI

struct FilterView: View {
    @ObservedObject var viewModel: RadarViewModel
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 20) {
                    // Handle
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppTheme.textSecondary.opacity(0.4))
                            .frame(width: 40, height: 5)
                        Spacer()
                    }
                    .padding(.top, 12)

                    Text("フィルター")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal, 20)

                    // Soup type chips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("スープ")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)

                        FlowLayout(spacing: 8) {
                            ForEach(SoupType.allCases, id: \.self) { soup in
                                chipButton(
                                    text: "\(soup.icon) \(soup.rawValue)",
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
                    .padding(.horizontal, 20)

                    // Price range chips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("価格帯")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)

                        HStack(spacing: 8) {
                            ForEach(PriceRange.allCases, id: \.self) { price in
                                chipButton(
                                    text: price.rawValue,
                                    isSelected: viewModel.selectedPriceRange == price
                                ) {
                                    viewModel.selectedPriceRange = viewModel.selectedPriceRange == price ? nil : price
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Toggle options
                    VStack(spacing: 12) {
                        toggleRow(icon: "moon.fill", text: "深夜営業のみ", isOn: $viewModel.lateNightOnly)
                        toggleRow(icon: "person.2.slash", text: "空いてる店優先", isOn: $viewModel.lowCongestionFirst)
                    }
                    .padding(.horizontal, 20)

                    // Reset button
                    Button {
                        viewModel.selectedSoupTypes.removeAll()
                        viewModel.selectedPriceRange = nil
                        viewModel.lateNightOnly = false
                        viewModel.lowCongestionFirst = false
                    } label: {
                        Text("リセット")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.textSecondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AppTheme.cardBackground)
                )
            }
        }
    }

    private func chipButton(text: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? AppTheme.neonRed : AppTheme.cardBackgroundLight)
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? AppTheme.neonRed : AppTheme.textSecondary.opacity(0.2), lineWidth: 1)
                        )
                )
        }
    }

    private func toggleRow(icon: String, text: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppTheme.neonYellow)
                .font(.system(size: 14))
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            Toggle("", isOn: isOn)
                .tint(AppTheme.neonRed)
                .labelsHidden()
        }
    }
}

// Simple flow layout for chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
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
