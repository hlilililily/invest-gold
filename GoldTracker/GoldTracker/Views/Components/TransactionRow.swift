import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    private var isBuy: Bool { transaction.type == .buy }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill((isBuy ? Color(hex: 0xF5A623) : Color(hex: 0x2196F3)).opacity(0.12))
                Image(systemName: isBuy ? "arrow.down.left" : "arrow.up.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isBuy ? Color(hex: 0xF5A623) : Color(hex: 0x2196F3))
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.type.rawValue)
                    .font(.system(.subheadline, weight: .semibold))

                HStack(spacing: 4) {
                    Text(Formatters.gramsString(transaction.grams))
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text("·")
                        .foregroundStyle(.quaternary)

                    Text(Formatters.dateShort.string(from: transaction.date))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(Formatters.priceString(transaction.pricePerGram) + "/g")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))

                if transaction.type == .sell {
                    Text(Formatters.profitString(transaction.realizedProfit))
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(GoldTheme.profitColor(transaction.realizedProfit))
                } else {
                    Text(Formatters.priceString(transaction.totalAmount))
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
