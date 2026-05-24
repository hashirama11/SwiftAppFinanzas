import Foundation

enum Formatters {
    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.locale = Locale(identifier: "es_VE")
        return f
    }()

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        return f
    }()

    static func formatCurrency(_ value: Double, simbolo: String) -> String {
        let formatted = currency.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        return "\(simbolo) \(formatted)"
    }

    static func formatDate(_ date: Date) -> String {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }

    static func formatDateShort(_ date: Date) -> String {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date)
    }

    static func formatMonth(_ date: Date) -> String {
        dateFormatter.dateFormat = "MMM"
        return dateFormatter.string(from: date).capitalized
    }

    static func formatCompact(_ value: Double) -> String {
        if abs(value) >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if abs(value) >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }
}
