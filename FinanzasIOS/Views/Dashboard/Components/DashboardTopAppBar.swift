import SwiftUI

struct DashboardTopAppBar: View {
    @Environment(\.appTheme) private var theme

    let userName: String

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("¡Hola, \(userName)!")
                    .font(theme.typography.headlineMedium)
                    .foregroundColor(theme.colors.textPrimary)

                Text(todayString)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var todayString: String {
        let f = Formatters.dateFormatter
        f.dateFormat = "EEEE d 'de' MMMM"
        return f.string(from: Date()).capitalized
    }
}
