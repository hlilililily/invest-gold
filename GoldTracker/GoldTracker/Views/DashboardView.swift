import SwiftUI

struct DashboardView: View {
    @Environment(PortfolioViewModel.self) private var viewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                portfolioSelector
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                heroCard
                    .padding(.horizontal)
                    .padding(.bottom, 20)

                marketPriceInput
                    .padding(.horizontal)
                    .padding(.bottom, 20)

                holdingGrid
                    .padding(.horizontal)
                    .padding(.bottom, 24)

                pnlSection
                    .padding(.horizontal)
                    .padding(.bottom, 24)

                recentTransactions
                    .padding(.horizontal)
                    .padding(.bottom, 32)
            }
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("黄金管家")
    }

    // MARK: - Portfolio Selector

    private var portfolioSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.allPortfolioNames, id: \.self) { name in
                    let selected = name == viewModel.selectedPortfolioName
                    Button {
                        withAnimation(.spring(duration: 0.35)) {
                            viewModel.selectedPortfolioName = name
                        }
                    } label: {
                        Text(name)
                            .font(.system(.subheadline, weight: .semibold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background {
                                if selected {
                                    Capsule()
                                        .fill(Color("BrandGold"))
                                } else {
                                    Capsule()
                                        .fill(Color.appSecondaryBackground)
                                }
                            }
                            .foregroundStyle(selected ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("持仓总览")
                            .font(.system(.subheadline, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))

                        Text(Formatters.gramsString(viewModel.holdingGrams))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("均价 \(Formatters.priceString(viewModel.averageCost))")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(.white.opacity(0.35))

                        if viewModel.currentMarketPrice > 0 && viewModel.holdingGrams > 0 {
                            ProfitBadge(
                                value: viewModel.unrealizedPnL,
                                percent: viewModel.unrealizedPnLPercent
                            )
                            .colorScheme(.dark)
                        }
                    }
                }

                HStack(spacing: 10) {
                    HeroStatCard(
                        title: "持仓成本",
                        value: Formatters.priceString(viewModel.totalCostBasis),
                        icon: "banknote"
                    )
                    if viewModel.currentMarketPrice > 0 {
                        HeroStatCard(
                            title: "当前市值",
                            value: Formatters.priceString(viewModel.totalMarketValue),
                            icon: "chart.bar.fill"
                        )
                    }
                }
            }
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xC8963E), Color(hex: 0xA67C2E), Color(hex: 0x8B6914)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                            .stroke(.white.opacity(0.15), lineWidth: 0.5)
                    }
            }
        }
    }

    // MARK: - Market Price

    private var marketPriceInput: some View {
        @Bindable var vm = viewModel

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color("BrandGold").opacity(0.12))
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color("BrandGold"))
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("实时金价")
                    .font(.system(.subheadline, weight: .semibold))
                Text("输入当前市场价格")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            HStack(spacing: 4) {
                Text("¥")
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("0.00", value: $vm.currentMarketPrice, format: .number)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                Text("/g")
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                .fill(Color.appBackground)
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        }
    }

    // MARK: - Holdings Grid

    private var holdingGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("收益详情")
                .font(.system(.headline, weight: .bold))

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                StatCard(
                    title: "已实现盈亏",
                    value: Formatters.profitString(viewModel.totalRealizedProfit),
                    valueColor: GoldTheme.profitColor(viewModel.totalRealizedProfit),
                    icon: "checkmark.seal.fill"
                )

                StatCard(
                    title: "累计投入",
                    value: Formatters.priceString(viewModel.totalInvested),
                    icon: "arrow.down.to.line"
                )

                if viewModel.currentMarketPrice > 0 {
                    StatCard(
                        title: "浮动盈亏",
                        value: Formatters.profitString(viewModel.unrealizedPnL),
                        subtitle: Formatters.percentString(viewModel.unrealizedPnLPercent),
                        valueColor: GoldTheme.profitColor(viewModel.unrealizedPnL),
                        icon: "waveform.path.ecg"
                    )

                    StatCard(
                        title: "总盈亏",
                        value: Formatters.profitString(viewModel.totalPnL),
                        valueColor: GoldTheme.profitColor(viewModel.totalPnL),
                        icon: "sum"
                    )
                }
            }
        }
    }

    // MARK: - P&L (kept for overview completeness)

    @ViewBuilder
    private var pnlSection: some View {
        if viewModel.currentMarketPrice > 0 && viewModel.holdingGrams > 0 {
            VStack(spacing: 12) {
                HStack {
                    Text("盈亏分析")
                        .font(.system(.headline, weight: .bold))
                    Spacer()
                }

                VStack(spacing: 0) {
                    pnlRow(label: "持仓均价", value: Formatters.priceString(viewModel.averageCost))
                    Divider().padding(.leading, 16)
                    pnlRow(label: "当前金价", value: Formatters.priceString(viewModel.currentMarketPrice))
                    Divider().padding(.leading, 16)
                    pnlRow(label: "价差", value: Formatters.profitString(viewModel.currentMarketPrice - viewModel.averageCost), valueColor: GoldTheme.profitColor(viewModel.currentMarketPrice - viewModel.averageCost))
                    Divider().padding(.leading, 16)
                    pnlRow(label: "浮动盈亏", value: Formatters.profitString(viewModel.unrealizedPnL), valueColor: GoldTheme.profitColor(viewModel.unrealizedPnL), bold: true)
                }
                .background {
                    RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                        .fill(Color.appBackground)
                        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
                }
            }
        }
    }

    private func pnlRow(label: String, value: String, valueColor: Color = .primary, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(.subheadline, weight: bold ? .semibold : .regular))
                .foregroundStyle(bold ? .primary : .secondary)
            Spacer()
            Text(value)
                .font(.system(bold ? .headline : .subheadline, design: .rounded, weight: bold ? .bold : .semibold))
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    // MARK: - Recent Transactions

    private var recentTransactions: some View {
        VStack(spacing: 12) {
            HStack {
                Text("最近交易")
                    .font(.system(.headline, weight: .bold))
                Spacer()
                NavigationLink {
                    TransactionListView()
                } label: {
                    HStack(spacing: 4) {
                        Text("全部")
                            .font(.system(.subheadline, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Color("BrandGold"))
                }
            }

            if viewModel.filteredTransactions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(.quaternary)
                    Text("暂无交易记录")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .background {
                    RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                        .fill(Color.appBackground)
                        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.filteredTransactions.prefix(5).enumerated()), id: \.element.id) { index, transaction in
                        TransactionRow(transaction: transaction)
                            .padding(.horizontal, 14)
                        if index < min(viewModel.filteredTransactions.count, 5) - 1 {
                            Divider().padding(.leading, 68)
                        }
                    }
                }
                .padding(.vertical, 6)
                .background {
                    RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                        .fill(Color.appBackground)
                        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
                }
            }
        }
    }
}
