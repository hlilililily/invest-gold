import SwiftUI

struct AnalyticsView: View {
    @Environment(PortfolioViewModel.self) private var viewModel

    @State private var selectedPreset: DatePreset = .all
    @State private var customStart: Date = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var customEnd: Date = .now
    @State private var showCustomPicker = false

    enum DatePreset: String, CaseIterable, Identifiable {
        case week7 = "近7天"
        case month1 = "近1月"
        case month3 = "近3月"
        case month6 = "近半年"
        case year1 = "近1年"
        case all = "全部"
        case custom = "自定义"

        var id: String { rawValue }
    }

    private var dateRange: ClosedRange<Date> {
        let end = Date.now
        let calendar = Calendar.current
        let start: Date
        switch selectedPreset {
        case .week7:  start = calendar.date(byAdding: .day, value: -7, to: end) ?? end
        case .month1: start = calendar.date(byAdding: .month, value: -1, to: end) ?? end
        case .month3: start = calendar.date(byAdding: .month, value: -3, to: end) ?? end
        case .month6: start = calendar.date(byAdding: .month, value: -6, to: end) ?? end
        case .year1:  start = calendar.date(byAdding: .year, value: -1, to: end) ?? end
        case .all:    start = viewModel.earliestTransactionDate ?? end
        case .custom: return customStart...customEnd
        }
        return start...end
    }

    private var metrics: GoldCalculator.PerformanceMetrics {
        viewModel.computeMetrics(dateRange: dateRange)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                datePresetSelector
                    .padding(.horizontal)

                if selectedPreset == .custom {
                    customDatePickers
                        .padding(.horizontal)
                }

                if viewModel.filteredTransactions.isEmpty {
                    emptyState
                        .padding(.top, 40)
                } else {
                    heroMetric
                        .padding(.horizontal)

                    returnMetrics
                        .padding(.horizontal)

                    cashFlowCard
                        .padding(.horizontal)

                    tradeStatsCard
                        .padding(.horizontal)

                    if metrics.sellCount > 0 {
                        winLossCard
                            .padding(.horizontal)
                    }

                    xirrCard
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("收益分析")
    }

    // MARK: - Date Preset Selector

    private var datePresetSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(DatePreset.allCases) { preset in
                    let selected = selectedPreset == preset
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedPreset = preset
                        }
                    } label: {
                        Text(preset.rawValue)
                            .font(.system(.caption, weight: .bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background {
                                if selected {
                                    Capsule().fill(Color("BrandGold"))
                                } else {
                                    Capsule().fill(Color(.secondarySystemBackground))
                                }
                            }
                            .foregroundStyle(selected ? .white : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Custom Date Pickers

    private var customDatePickers: some View {
        VStack(spacing: 0) {
            DatePicker("起始日期", selection: $customStart, displayedComponents: .date)
                .font(.system(.subheadline, weight: .medium))
                .padding(14)

            Divider().padding(.leading, 16)

            DatePicker("结束日期", selection: $customEnd, displayedComponents: .date)
                .font(.system(.subheadline, weight: .medium))
                .padding(14)
        }
        .background {
            RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(.quaternary)
            Text("暂无交易数据")
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("添加交易记录后查看收益分析")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Hero Metric

    private var heroMetric: some View {
        let m = metrics
        return VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("区间总收益")
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))

                Text(Formatters.profitString(m.totalPnL))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                HStack(spacing: 12) {
                    metriBadge(label: "收益率", value: Formatters.percentString(m.simpleReturn))
                    if let ann = m.annualizedReturn {
                        metriBadge(label: "年化", value: Formatters.percentString(ann))
                    }
                    metriBadge(label: "\(m.dayCount) 天", value: "")
                }
            }

            HStack(spacing: 10) {
                heroSub(title: "已实现", value: Formatters.profitString(m.realizedProfit))
                heroSub(title: "浮动", value: Formatters.profitString(m.unrealizedProfit))
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: m.totalPnL >= 0
                            ? [Color(hex: 0x1B8A4E), Color(hex: 0x14693A)]
                            : [Color(hex: 0xC0392B), Color(hex: 0x962D22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 0.5)
                }
        }
    }

    private func metriBadge(label: String, value: String) -> some View {
        HStack(spacing: 3) {
            if !label.isEmpty {
                Text(label)
                    .font(.system(.caption2, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            if !value.isEmpty {
                Text(value)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(.white.opacity(0.15)))
    }

    private func heroSub(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(.caption2, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: GoldTheme.innerRadius, style: .continuous).fill(.white.opacity(0.1)))
    }

    // MARK: - Return Metrics

    private var returnMetrics: some View {
        let m = metrics
        return VStack(spacing: 12) {
            sectionTitle("收益指标", icon: "chart.line.uptrend.xyaxis")

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                StatCard(
                    title: "简单收益率",
                    value: Formatters.percentString(m.simpleReturn),
                    subtitle: "总收益 / 总投入",
                    valueColor: GoldTheme.profitColor(m.simpleReturn),
                    icon: "percent",
                    compact: true
                )
                if let ann = m.annualizedReturn {
                    StatCard(
                        title: "年化收益率",
                        value: Formatters.percentString(ann),
                        subtitle: "折算365天",
                        valueColor: GoldTheme.profitColor(ann),
                        icon: "calendar",
                        compact: true
                    )
                }
                StatCard(
                    title: "日均收益",
                    value: Formatters.priceString(m.dailyAverageProfit),
                    subtitle: "\(m.dayCount) 天平均",
                    valueColor: GoldTheme.profitColor(m.dailyAverageProfit),
                    icon: "sun.min",
                    compact: true
                )
                StatCard(
                    title: "持仓天数",
                    value: "\(m.dayCount) 天",
                    icon: "clock",
                    compact: true
                )
            }
        }
    }

    // MARK: - Cash Flow Card

    private var cashFlowCard: some View {
        let m = metrics
        return VStack(spacing: 12) {
            sectionTitle("资金流向", icon: "arrow.left.arrow.right")

            VStack(spacing: 0) {
                cfRow(label: "累计买入", value: Formatters.priceString(m.totalBuyAmount), detail: "\(m.buyCount) 笔 · \(Formatters.gramsString(m.totalBuyGrams))", color: Color(hex: 0xF5A623))
                Divider().padding(.leading, 16)
                cfRow(label: "累计卖出", value: Formatters.priceString(m.totalSellAmount), detail: "\(m.sellCount) 笔 · \(Formatters.gramsString(m.totalSellGrams))", color: Color(hex: 0x2196F3))
                Divider().padding(.leading, 16)
                cfRow(label: "净投入", value: Formatters.priceString(m.netInvested), color: .primary)

                if m.endPosition.totalGrams > 0 {
                    Divider().padding(.leading, 16)
                    cfRow(label: "期末持仓", value: Formatters.gramsString(m.endPosition.totalGrams), detail: "均价 \(Formatters.priceString(m.endPosition.averageCost))", color: Color("BrandGold"))
                }
                if viewModel.currentMarketPrice > 0 && m.marketValue > 0 {
                    Divider().padding(.leading, 16)
                    cfRow(label: "期末市值", value: Formatters.priceString(m.marketValue), color: .primary)
                }
            }
            .background {
                RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
            }
        }
    }

    private func cfRow(label: String, value: String, detail: String? = nil, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(.secondary)
                if let detail {
                    Text(detail)
                        .font(.system(.caption2, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Trade Stats

    private var tradeStatsCard: some View {
        let m = metrics
        return VStack(spacing: 12) {
            sectionTitle("交易统计", icon: "number")

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                StatCard(title: "总交易笔数", value: "\(m.buyCount + m.sellCount)", subtitle: "买\(m.buyCount) / 卖\(m.sellCount)", icon: "list.number", compact: true)
                StatCard(title: "买入克数", value: Formatters.gramsString(m.totalBuyGrams), icon: "arrow.down.left", compact: true)
                StatCard(title: "卖出克数", value: Formatters.gramsString(m.totalSellGrams), icon: "arrow.up.right", compact: true)
                StatCard(title: "净买入", value: Formatters.gramsString(m.totalBuyGrams - m.totalSellGrams), icon: "scalemass", compact: true)
            }
        }
    }

    // MARK: - Win/Loss Card

    private var winLossCard: some View {
        let m = metrics
        return VStack(spacing: 12) {
            sectionTitle("盈亏分布", icon: "chart.pie")

            VStack(spacing: 14) {
                if let wr = m.winRate {
                    winRateBar(winRate: wr)
                }

                HStack(spacing: 10) {
                    StatCard(
                        title: "最大盈利",
                        value: Formatters.profitString(m.maxWin),
                        valueColor: GoldTheme.profit,
                        icon: "arrow.up.circle.fill",
                        compact: true
                    )
                    StatCard(
                        title: "最大亏损",
                        value: Formatters.profitString(m.maxLoss),
                        valueColor: m.maxLoss < 0 ? GoldTheme.loss : GoldTheme.neutral,
                        icon: "arrow.down.circle.fill",
                        compact: true
                    )
                }
            }
        }
    }

    private func winRateBar(winRate: Double) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("胜率")
                    .font(.system(.subheadline, weight: .semibold))
                Spacer()
                Text(Formatters.percentString(winRate))
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(winRate >= 0.5 ? GoldTheme.profit : GoldTheme.loss)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 10)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [GoldTheme.profit, GoldTheme.profit.opacity(0.7)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: max(4, geo.size.width * winRate), height: 10)
                }
            }
            .frame(height: 10)

            HStack {
                Text("盈利")
                    .font(.caption2)
                    .foregroundStyle(GoldTheme.profit)
                Spacer()
                Text("亏损")
                    .font(.caption2)
                    .foregroundStyle(GoldTheme.loss)
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: GoldTheme.innerRadius, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        }
    }

    // MARK: - XIRR Card

    @ViewBuilder
    private var xirrCard: some View {
        let m = metrics
        VStack(spacing: 12) {
            sectionTitle("高级指标", icon: "function")

            VStack(spacing: 0) {
                if let xirr = m.xirr {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("XIRR 内部收益率")
                                .font(.system(.subheadline, weight: .semibold))
                            Text("基于实际现金流时间加权计算，是衡量不规则投资回报最准确的指标")
                                .font(.system(.caption2, weight: .medium))
                                .foregroundStyle(.tertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        Text(Formatters.percentString(xirr))
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(GoldTheme.profitColor(xirr))
                    }
                    .padding(16)
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Color("BrandGold").opacity(0.6))
                        Text("XIRR 需要输入当前金价且同时包含买入和卖出/持仓数据")
                            .font(.system(.caption, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                }
            }
            .background {
                RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
            }
        }
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color("BrandGold"))
            Text(title)
                .font(.system(.headline, weight: .bold))
            Spacer()
        }
    }
}
