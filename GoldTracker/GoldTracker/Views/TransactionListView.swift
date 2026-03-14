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
        case .all:
            return viewModel.filteredTransactions
        case .buy:
            return viewModel.filteredTransactions.filter { $0.type == .buy }
        case .sell:
            return viewModel.filteredTransactions.filter { $0.type == .sell }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("筛选", selection: $filterType) {
                ForEach(TransactionFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            if filtered.isEmpty {
                ContentUnavailableView(
                    "暂无交易记录",
                    systemImage: "tray",
                    description: Text("添加买入或卖出记录开始追踪")
                )
            } else {
                List {
                    summaryHeader

                    ForEach(filtered) { transaction in
                        TransactionRow(transaction: transaction)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.deleteTransaction(transaction)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("交易记录")
    }

    private var summaryHeader: some View {
        let buyCount = viewModel.filteredTransactions.filter { $0.type == .buy }.count
        let sellCount = viewModel.filteredTransactions.filter { $0.type == .sell }.count
        let totalBuyAmount = viewModel.filteredTransactions
            .filter { $0.type == .buy }
            .reduce(0.0) { $0 + $1.totalAmount }
        let totalSellAmount = viewModel.filteredTransactions
            .filter { $0.type == .sell }
            .reduce(0.0) { $0 + $1.totalAmount }

        return Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("买入 \(buyCount) 笔")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(Formatters.priceString(totalBuyAmount))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("卖出 \(sellCount) 笔")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text(Formatters.priceString(totalSellAmount))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
    }
}
