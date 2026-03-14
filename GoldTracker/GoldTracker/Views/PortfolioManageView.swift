import SwiftUI

struct PortfolioManageView: View {
    @Environment(PortfolioViewModel.self) private var viewModel
    @State private var newPortfolioName = ""
    @State private var showAddSheet = false
    @State private var portfolioToDelete: Portfolio?

    var body: some View {
        List {
            Section("所有策略") {
                ForEach(viewModel.portfolios) { portfolio in
                    portfolioRow(portfolio)
                }
            }

            if viewModel.currentMarketPrice > 0 {
                Section("汇总") {
                    let summary = viewModel.allPortfoliosSummary
                    let totalUnrealized = viewModel.portfolios.reduce(0.0) {
                        $0 + viewModel.unrealizedPnLForPortfolio($1)
                    }

                    HStack {
                        Text("总持仓")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(Formatters.gramsString(summary.grams))
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text("总成本")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(Formatters.priceString(summary.costBasis))
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text("总市值")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(Formatters.priceString(summary.grams * viewModel.currentMarketPrice))
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text("已实现盈亏")
                            .foregroundStyle(.secondary)
                        Spacer()
                        ProfitText(value: summary.realized, font: .body.weight(.medium))
                    }

                    HStack {
                        Text("浮动盈亏")
                            .foregroundStyle(.secondary)
                        Spacer()
                        ProfitText(value: totalUnrealized, font: .body.weight(.medium))
                    }

                    HStack {
                        Text("总盈亏")
                            .foregroundStyle(.secondary)
                        Spacer()
                        ProfitText(
                            value: summary.realized + totalUnrealized,
                            font: .body.weight(.semibold)
                        )
                    }
                }
            }
        }
        .navigationTitle("策略管理")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("新建策略", isPresented: $showAddSheet) {
            TextField("策略名称", text: $newPortfolioName)
            Button("取消", role: .cancel) {
                newPortfolioName = ""
            }
            Button("创建") {
                viewModel.addPortfolio(name: newPortfolioName)
                newPortfolioName = ""
            }
        } message: {
            Text("输入新的策略名称（如：长线、短线、波段）")
        }
        .alert("确认删除", isPresented: .init(
            get: { portfolioToDelete != nil },
            set: { if !$0 { portfolioToDelete = nil } }
        )) {
            Button("取消", role: .cancel) {
                portfolioToDelete = nil
            }
            Button("删除", role: .destructive) {
                if let p = portfolioToDelete {
                    viewModel.deletePortfolio(p)
                }
                portfolioToDelete = nil
            }
        } message: {
            if let p = portfolioToDelete {
                Text("将删除「\(p.name)」及其所有交易记录，此操作不可撤销")
            }
        }
    }

    private func portfolioRow(_ portfolio: Portfolio) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(portfolio.name)
                    .font(.headline)

                if portfolio.name == viewModel.selectedPortfolioName {
                    Text("当前")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.orange.opacity(0.2))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }

                Spacer()

                Button {
                    viewModel.selectedPortfolioName = portfolio.name
                } label: {
                    Text("选择")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }

            HStack(spacing: 16) {
                Label(Formatters.gramsString(portfolio.totalGrams), systemImage: "scalemass")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label(
                    "均价 \(Formatters.priceString(portfolio.averageCost))",
                    systemImage: "tag"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                Label(
                    "已实现 \(Formatters.profitString(portfolio.totalRealizedProfit))",
                    systemImage: "checkmark.circle"
                )
                .font(.caption)
                .foregroundStyle(portfolio.totalRealizedProfit >= 0 ? .red : .green)

                if viewModel.currentMarketPrice > 0 {
                    let unrealized = viewModel.unrealizedPnLForPortfolio(portfolio)
                    Label(
                        "浮动 \(Formatters.profitString(unrealized))",
                        systemImage: "chart.line.flattrend.xyaxis"
                    )
                    .font(.caption)
                    .foregroundStyle(unrealized >= 0 ? .red : .green)
                }
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button(role: .destructive) {
                portfolioToDelete = portfolio
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
}
