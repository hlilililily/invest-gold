import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    private var isBuy: Bool { transaction.type == .buy }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.type.icon)
                .font(.title2)
                .foregroundStyle(isBuy ? .orange : .blue)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(transaction.type.rawValue)
                        .font(.headline)

                    Text(Formatters.gramsString(transaction.grams))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(Formatters.dateShort.string(from: transaction.date))
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(Formatters.priceString(transaction.pricePerGram) + "/g")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(Formatters.priceString(transaction.totalAmount))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if transaction.type == .sell {
                    Text(Formatters.profitString(transaction.realizedProfit))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(transaction.realizedProfit >= 0 ? .red : .green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
