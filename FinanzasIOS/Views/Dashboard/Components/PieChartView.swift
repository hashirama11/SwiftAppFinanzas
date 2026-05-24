import SwiftUI
import Charts

struct PieChartView: View {
    @Environment(\.appTheme) private var theme

    let dataVes: [PieChartData]
    let dataUsd: [PieChartData]
    let isIncome: Bool

    @State private var selectedCurrency: Moneda = .VES
    @State private var selectedAngle: Double?
    @State private var selectedCategory: PieChartData?

    private var currentData: [PieChartData] {
        selectedCurrency == .VES ? dataVes : dataUsd
    }

    private var title: String {
        let base = isIncome ? "Distribución de Ingresos" : "Distribución de Gastos"
        return "\(base) (\(selectedCurrency.simbolo))"
    }

    private var emptyMessage: String {
        isIncome ? "Sin ingresos en \(selectedCurrency.nombre)" : "Sin gastos en \(selectedCurrency.nombre)"
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(theme.typography.titleMedium)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                Picker("Moneda", selection: $selectedCurrency) {
                    ForEach(Moneda.allCases, id: \.self) { moneda in
                        Text(moneda.simbolo).tag(moneda)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }

            if currentData.isEmpty {
                emptyChartView
            } else {
                chartContent
            }
        }
        .padding(16)
        .cardBackground()
        .padding(.horizontal, 20)
        .onChange(of: selectedCurrency) { _, _ in
            selectedAngle = nil
            selectedCategory = nil
        }
    }

    private var chartContent: some View {
        VStack(spacing: 16) {
            Chart(currentData) { item in
                SectorMark(
                    angle: .value("Valor", item.value),
                    innerRadius: .ratio(0.6),
                    outerRadius: selectedCategory == item ? .ratio(1.02) : .ratio(1.0),
                    angularInset: 1.5
                )
                .foregroundStyle(item.color)
                .cornerRadius(4)
            }
            .frame(height: 220)
            .chartAngleSelection(value: $selectedAngle)
            .onChange(of: selectedAngle) { _, newAngle in
                if let angle = newAngle {
                    selectedCategory = findSelectedCategory(angle: angle)
                } else {
                    selectedCategory = nil
                }
            }

            legendView
        }
    }

    private var legendView: some View {
        VStack(spacing: 8) {
            ForEach(currentData) { item in
                HStack {
                    Circle()
                        .fill(item.color)
                        .frame(width: 10, height: 10)
                    Text(item.categoryName)
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text(String(format: "%.0f%%", item.value * 100))
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 4)
    }

    private var emptyChartView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 40))
                .foregroundColor(theme.colors.textSecondary.opacity(0.4))

            Text(emptyMessage)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(height: 200)
    }

    private func findSelectedCategory(angle: Double) -> PieChartData? {
        let normalizedAngle = (angle / (2 * .pi)).truncatingRemainder(dividingBy: 1)
        var cumulative: Double = 0
        for item in currentData {
            cumulative += item.value
            if normalizedAngle <= cumulative {
                return item
            }
        }
        return nil
    }
}
