import SwiftUI

struct DashboardTabRow: View {
    @Environment(\.appTheme) private var theme

    @Binding var selectedTab: Int

    private let tabs = ["Ingresos", "Gastos"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, title in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(title)
                            .font(theme.typography.labelMedium)
                            .fontWeight(selectedTab == index ? .semibold : .regular)
                            .foregroundColor(
                                selectedTab == index
                                    ? theme.colors.primary
                                    : theme.colors.textSecondary
                            )

                        Capsule()
                            .fill(
                                selectedTab == index
                                    ? theme.colors.primary
                                    : Color.clear
                            )
                            .frame(height: 3)
                            .frame(width: selectedTab == index ? 24 : 0)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
    }
}
