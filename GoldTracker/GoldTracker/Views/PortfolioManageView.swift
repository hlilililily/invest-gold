import SwiftUI

struct PortfolioManageView: View {
    @Environment(PortfolioViewModel.self) private var viewModel
    @State private var newPortfolioName = ""
    @State private var showAddSheet = false
    @State private var portfolioToDelete: Portfolio?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                portfolioList

                if viewModel.currentMarketPrice > 0 {
                    globalSummary
                }
            }
            .padding(20)
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("策略管理")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.title3)
                        .foregroundStyle(Color("BrandGold"))
                }
            }
        }
        .alert("新建策略", isPresented: $showAddSheet) {
            TextField("策略名称", text: $newPortfolioName)
            Button("取消", role: .cancel) { newPortfolioName = "" }
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
            Button("取消", role: .cancel) { portfolioToDelete = nil }
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

    // MARK: - Portfolio List

    private var portfolioList: some View {
        VStack(spacing: 12) {
            HStack {
                Text("投资策略")
                    .font(.system(.headline, weight: .bold))
                Spacer()
                Text("\(viewModel.portfolios.count) 个策略")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            ForEach(viewModel.portfolios) { portfolio in
                portfolioCard(portfolio)
            }
        }
    }

    private func portfolioCard(_ portfolio: Portfolio) -> some View {
        let isActive = portfolio.name == viewModel.selectedPortfolioName
        let unrealized = viewModel.unrealizedPnLForPortfolio(portfolio)

        return VStack(spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(portfolio.name)
                            .font(.system(.headline, weight: .bold))
                        if isActive {
                            Text("当前")
                                .font(.system(.caption2, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color("BrandGold"))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    Text("持仓 \(Formatters.gramsString(portfolio.totalGrams))  ·  均价 \(Formatters.priceString(portfolio.averageCost))")
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !isActive {
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            viewModel.selectedPortfolioName = portfolio.name
                        }
                    } label: {
                        Text("选择")
                            .font(.system(.caption, weight: .bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background {
                                Capsule().stroke(Color("BrandGold"), lineWidth: 1.5)
                            }
                            .foregroundStyle(Color("BrandGold"))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 0) {
                miniStat(label: "已实现", value: Formatters.profitString(portfolio.totalRealizedProfit), color: GoldTheme.profitColor(portfolio.totalRealizedProfit))

                Rectangle()
                    .fill(.quaternary)
                    .frame(width: 1, height: 28)
                    .padding(.horizontal, 8)

                if viewModel.currentMarketPrice > 0 {
                    miniStat(label: "浮动", value: Formatters.profitString(unrealized), color: GoldTheme.profitColor(unrealized))

                    Rectangle()
                        .fill(.quaternary)
                        .frame(width: 1, height: 28)
                        .padding(.horizontal, 8)

                    miniStat(label: "总盈亏", value: Formatters.profitString(portfolio.totalRealizedProfit + unrealized), color: GoldTheme.profitColor(portfolio.totalRealizedProfit + unrealized))
                } else {
                    miniStat(label: "累计投入", value: Formatters.priceString(portfolio.totalInvested), color: .primary)
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                .fill(Color.appBackground)
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
                .overlay {
                    if isActive {
                        RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                            .stroke(Color("BrandGold").opacity(0.3), lineWidth: 1.5)
                    }
                }
        }
        .contextMenu {
            Button(role: .destructive) {
                portfolioToDelete = portfolio
            } label: {
                Label("删除策略", systemImage: "trash")
            }
        }
    }

    private func miniStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(.caption2, weight: .medium))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Global Summary

    private var globalSummary: some View {
        let summary = viewModel.allPortfoliosSummary
        let totalUnrealized = viewModel.portfolios.reduce(0.0) { $0 + viewModel.unrealizedPnLForPortfolio($1) }
        let totalPnL = summary.realized + totalUnrealized

        return VStack(spacing: 14) {
            HStack {
                Text("全局汇总")
                    .font(.system(.headline, weight: .bold))
                Spacer()
            }

            VStack(spacing: 0) {
                summaryRow(label: "总持仓", value: Formatters.gramsString(summary.grams))
                Divider().padding(.leading, 16)
                summaryRow(label: "总成本", value: Formatters.priceString(summary.costBasis))
                Divider().padding(.leading, 16)
                summaryRow(label: "总市值", value: Formatters.priceString(summary.grams * viewModel.currentMarketPrice))
                Divider().padding(.leading, 16)
                summaryRow(label: "已实现盈亏", value: Formatters.profitString(summary.realized), valueColor: GoldTheme.profitColor(summary.realized))
                Divider().padding(.leading, 16)
                summaryRow(label: "浮动盈亏", value: Formatters.profitString(totalUnrealized), valueColor: GoldTheme.profitColor(totalUnrealized))

                Rectangle()
                    .fill(Color("BrandGold").opacity(0.15))
                    .frame(height: 1)

                HStack {
                    Text("总盈亏")
                        .font(.system(.subheadline, weight: .bold))
                    Spacer()
                    Text(Formatters.profitString(totalPnL))
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(GoldTheme.profitColor(totalPnL))
                }
                .padding(16)
            }
            .background {
                RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                    .fill(Color.appBackground)
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
            }
        }
    }

    private func summaryRow(label: String, value: String, valueColor: Color = .primary) -> some View {
        HStack {
            Text(label)
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
