import SwiftUI

struct ProfitText: View {
    let value: Double
    var font: Font = .body
    var showSign: Bool = true

    private var color: Color {
        if value > 0 { return .red }
        if value < 0 { return .green }
        return .secondary
    }

    var body: some View {
        Text(showSign ? Formatters.profitString(value) : Formatters.priceString(value))
            .font(font)
            .foregroundStyle(color)
    }
}
