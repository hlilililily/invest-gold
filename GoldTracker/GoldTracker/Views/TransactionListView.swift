import SwiftUI

struct TransactionListView: View {
    @Environment(PortfolioViewModel.self) private var viewModel
    @State private var filterType: TransactionFilter = .all

    enum TransactionFilter: String, CaseIterable {
        case all = "全部"
        case buy = "买入"
        case sell = "卖出"
    }

    private var filtered: [Transaction] {
        switch filterType {
        case .all:  return viewModel.filteredTransactions
        case .buy:  return viewModel.filteredTransactions.filter { $0.type == .buy }
        case .sell: return viewModel.filteredTransactions.filter { $0.type == .sell }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

            summaryBanner
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            if filtered.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                transactionList
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("交易记录")
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 0) {
            ForEach(TransactionFilter.allCases, id: \.self) { filter in
                let selected = filterType == filter
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        filterType = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.system(.subheadline, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selected {
                                Capsule()
                                    .fill(Color("BrandGold"))
                            }
                        }
                        .foregroundStyle(selected ? .white : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background {
            Capsule().fill(Color(.secondarySystemBackground))
        }
    }

    // MARK: - Summary Banner

    private var summaryBanner: some View {
        let buyTx = viewModel.filteredTransactions.filter { $0.type == .buy }
        let sellTx = viewModel.filteredTransactions.filter { $0.type == .sell }
        let buyAmount = buyTx.reduce(0.0) { $0 + $1.totalAmount }
        let sellAmount = sellTx.reduce(0.0) { $0 + $1.totalAmount }

        return HStack(spacing: 16) {
            summaryPill(
                icon: "arrow.down.left",
                color: Color(hex: 0xF5A623),
                label: "买入 \(buyTx.count) 笔",
                value: Formatters.priceString(buyAmount)
            )
            summaryPill(
                icon: "arrow.up.right",
                color: Color(hex: 0x2196F3),
                label: "卖出 \(sellTx.count) 笔",
                value: Formatters.priceString(sellAmount)
            )
        }
    }

    private func summaryPill(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(color.opacity(0.12))
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color)
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(.caption2, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: GoldTheme.innerRadius, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundStyle(.quaternary)
            Text("暂无交易记录")
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("点击右上角 + 按钮添加记录")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Transaction List

    private var transactionList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(filtered.enumerated()), id: \.element.id) { index, transaction in
                    TransactionRow(transaction: transaction)
                        .padding(.horizontal, 16)
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation {
                                    viewModel.deleteTransaction(transaction)
                                }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }

                    if index < filtered.count - 1 {
                        Divider().padding(.leading, 70)
                    }
                }
            }
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
}
