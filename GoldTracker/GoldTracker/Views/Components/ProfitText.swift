import SwiftUI

struct ProfitText: View {
    let value: Double
    var font: Font = .body
    var showSign: Bool = true
    var animated: Bool = false

    var body: some View {
        if animated {
            AnimatedNumber(
                value: value,
                formatter: { showSign ? Formatters.profitString($0) : Formatters.priceString($0) },
                font: font,
                color: GoldTheme.profitColor(value)
            )
        } else {
            Text(showSign ? Formatters.profitString(value) : Formatters.priceString(value))
                .font(font)
                .foregroundStyle(GoldTheme.profitColor(value))
        }
    }
}

struct ProfitBadge: View {
    let value: Double
    let percent: Double?

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: value >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 10, weight: .bold))

            Text(Formatters.profitString(value))
                .font(.system(.caption, design: .rounded, weight: .bold))

            if let percent {
                Text(Formatters.percentString(percent))
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .opacity(0.8)
            }
        }
        .foregroundStyle(GoldTheme.profitColor(value))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background {
            Capsule()
                .fill(GoldTheme.profitColor(value).opacity(0.12))
        }
    }
}
