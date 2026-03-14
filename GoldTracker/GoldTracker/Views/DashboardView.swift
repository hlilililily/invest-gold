import SwiftUI

struct DashboardView: View {
    @Environment(PortfolioViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        ScrollView {
            VStack(spacing: 20) {
                headerSection
                marketPriceInput
                holdingCards
                pnlSection
                quickActions
            }
            .padding()
        }
        .navigationTitle("黄金管家")
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("当前策略")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.allPortfolioNames, id: \.self) { name in
                        portfolioChip(name: name, isSelected: name == viewModel.selectedPortfolioName)
                    }
                }
            }
        }
    }

    private func portfolioChip(name: String, isSelected: Bool) -> some View {
        Button {
            viewModel.selectedPortfolioName = name
        } label: {
            Text(name)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.orange : Color.gray.opacity(0.15))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Market Price

    private var marketPriceInput: some View {
        @Bindable var vm = viewModel

        return HStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .foregroundStyle(.orange)
            Text("实时金价")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            TextField("输入当前金价", value: $vm.currentMarketPrice, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 140)
                .multilineTextAlignment(.trailing)
            Text("¥/g")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        #if os(iOS)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        #else
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        #endif
    }

    // MARK: - Holding Cards

    private var holdingCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 10) {
            StatCard(
                title: "持仓克数",
                value: Formatters.gramsString(viewModel.holdingGrams),
                icon: "scalemass"
            )
            StatCard(
                title: "持仓均价",
                value: Formatters.priceString(viewModel.averageCost),
                subtitle: "每克",
                icon: "tag"
            )
            StatCard(
                title: "持仓成本",
                value: Formatters.priceString(viewModel.totalCostBasis),
                icon: "banknote"
            )
            StatCard(
                title: "市值",
                value: viewModel.currentMarketPrice > 0
                    ? Formatters.priceString(viewModel.totalMarketValue)
                    : "--",
                icon: "chart.bar"
            )
        }
    }

    // MARK: - P&L Section

    private var pnlSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("收益概览")
                    .font(.headline)
                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                StatCard(
                    title: "已实现盈亏",
                    value: Formatters.profitString(viewModel.totalRealizedProfit),
                    valueColor: viewModel.totalRealizedProfit >= 0 ? .red : .green,
                    icon: "checkmark.circle"
                )

                if viewModel.currentMarketPrice > 0 {
                    StatCard(
                        title: "浮动盈亏",
                        value: Formatters.profitString(viewModel.unrealizedPnL),
                        subtitle: Formatters.percentString(viewModel.unrealizedPnLPercent),
                        valueColor: viewModel.unrealizedPnL >= 0 ? .red : .green,
                        icon: "chart.line.flattrend.xyaxis"
                    )
                }

                StatCard(
                    title: "累计投入",
                    value: Formatters.priceString(viewModel.totalInvested),
                    icon: "arrow.down.circle"
                )

                if viewModel.currentMarketPrice > 0 {
                    StatCard(
                        title: "总盈亏",
                        value: Formatters.profitString(viewModel.totalPnL),
                        valueColor: viewModel.totalPnL >= 0 ? .red : .green,
                        icon: "sum"
                    )
                }
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(spacing: 10) {
            HStack {
                Text("最近交易")
                    .font(.headline)
                Spacer()
                NavigationLink("查看全部") {
                    TransactionListView()
                }
                .font(.subheadline)
            }

            if viewModel.filteredTransactions.isEmpty {
                ContentUnavailableView(
                    "暂无交易记录",
                    systemImage: "tray",
                    description: Text("点击右下角按钮添加买入或卖出记录")
                )
                .frame(height: 150)
            } else {
                ForEach(viewModel.filteredTransactions.prefix(5)) { transaction in
                    TransactionRow(transaction: transaction)
                    if transaction.id != viewModel.filteredTransactions.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}
