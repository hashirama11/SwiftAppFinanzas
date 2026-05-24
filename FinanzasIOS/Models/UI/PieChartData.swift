import SwiftUI

struct PieChartData: Identifiable, Hashable {
    var id: String { categoryName }
    let value: Double
    let color: Color
    let categoryName: String
}
