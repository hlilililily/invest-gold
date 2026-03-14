import SwiftUI

struct CalculatorView: View {
    @State private var holdingGrams: String = ""
    @State private var holdingAvgCost: String = ""
    @State private var actionType: TransactionType = .buy
    @State private var actionGrams: String = ""
    @State private var actionPrice: String = ""
    @State private var sellPrice: String = ""

    private var currentPosition: GoldCalculator.PositionSnapshot {
        let g = Double(holdingGrams) ?? 0
        let c = Double(holdingAvgCost) ?? 0
        return GoldCalculator.PositionSnapshot(
            totalGrams: g, averageCost: c, totalCostBasis: g * c, realizedProfit: 0
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                positionCard
                actionCard
                resultCard
                if actionType == .buy { sellSimulationCard }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("收益计算器")
    }

    // MARK: - Position Card

    private var positionCard: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "briefcase.fill")
                    .foregroundStyle(Color("BrandGold"))
                Text("当前持仓")
                    .font(.system(.subheadline, weight: .bold))
                Spacer()
                if currentPosition.totalGrams > 0 {
                    Text("成本 \(Formatters.priceString(currentPosition.totalCostBasis))")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)

            Divider().padding(.leading, 16)

            inputRow(label: "持仓克数", text: $holdingGrams, unit: "g", placeholder: "0")
            Divider().padding(.leading, 16)
            inputRow(label: "持仓均价", text: $holdingAvgCost, unit: "¥/g", placeholder: "0.00")
        }
        .background {
            RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        }
    }

    // MARK: - Action Card

    private var actionCard: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundStyle(Color("BrandGold"))
                Text("模拟操作")
                    .font(.system(.subheadline, weight: .bold))
                Spacer()
            }
            .padding(16)

            Divider().padding(.leading, 16)

            HStack(spacing: 0) {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    let selected = actionType == type
                    Button {
                        withAnimation(.spring(duration: 0.3)) { actionType = type }
                    } label: {
                        Text(type.rawValue)
                            .font(.system(.subheadline, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background {
                                if selected {
                                    Capsule().fill(type == .buy ? Color(hex: 0xF5A623) : Color(hex: 0x2196F3))
                                }
                            }
                            .foregroundStyle(selected ? .white : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .padding(.horizontal, 12)
            .padding(.bottom, 4)

            Divider().padding(.leading, 16)

            inputRow(label: actionType == .buy ? "买入克数" : "卖出克数", text: $actionGrams, unit: "g", placeholder: "0")
            Divider().padding(.leading, 16)
            inputRow(label: actionType == .buy ? "买入单价" : "卖出单价", text: $actionPrice, unit: "¥/g", placeholder: "0.00")
        }
        .background {
            RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        }
    }

    // MARK: - Result Card

    @ViewBuilder
    private var resultCard: some View {
        let g = Double(actionGrams) ?? 0
        let p = Double(actionPrice) ?? 0

        if g > 0 && p > 0 && currentPosition.totalGrams > 0 {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color("BrandGold"))
                    Text("计算结果")
                        .font(.system(.subheadline, weight: .bold))
                    Spacer()
                }
                .padding(16)

                Divider().padding(.leading, 16)

                switch actionType {
                case .buy:
                    let result = GoldCalculator.buy(
                        currentPosition: currentPosition,
                        grams: g,
                        pricePerGram: p
                    )
                    resultRow("交易金额", Formatters.priceString(g * p))
                    Divider().padding(.leading, 16)
                    resultRow("新持仓", Formatters.gramsString(result.newPosition.totalGrams))
                    Divider().padding(.leading, 16)
                    resultRow("新均价", Formatters.priceString(result.newPosition.averageCost), highlight: true)
                    Divider().padding(.leading, 16)
                    resultRow("新成本", Formatters.priceString(result.newPosition.totalCostBasis))

                case .sell:
                    let sellGrams = min(g, currentPosition.totalGrams)
                    let result = GoldCalculator.sell(
                        currentPosition: currentPosition,
                        grams: sellGrams,
                        pricePerGram: p
                    )
                    resultRow("交易金额", Formatters.priceString(sellGrams * p))
                    Divider().padding(.leading, 16)
                    resultRow("成本均价", Formatters.priceString(currentPosition.averageCost))
                    Divider().padding(.leading, 16)

                    HStack {
                        Text("本次盈亏")
                            .font(.system(.subheadline, weight: .bold))
                        Spacer()
                        ProfitText(value: result.transactionProfit, font: .system(.headline, design: .rounded, weight: .bold))
                    }
                    .padding(16)
                    .background(GoldTheme.profitColor(result.transactionProfit).opacity(0.06))

                    Divider().padding(.leading, 16)
                    resultRow("剩余持仓", Formatters.gramsString(result.newPosition.totalGrams))
                    if result.newPosition.totalGrams > 0 {
                        Divider().padding(.leading, 16)
                        resultRow("剩余均价", Formatters.priceString(result.newPosition.averageCost))
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
            }
        }
    }

    // MARK: - Sell Simulation

    @ViewBuilder
    private var sellSimulationCard: some View {
        let buyG = Double(actionGrams) ?? 0
        let buyP = Double(actionPrice) ?? 0

        if buyG > 0 && buyP > 0 && currentPosition.totalGrams > 0 {
            let afterBuy = GoldCalculator.buy(
                currentPosition: currentPosition,
                grams: buyG,
                pricePerGram: buyP
            ).newPosition

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "arrow.triangle.swap")
                        .foregroundStyle(Color("BrandGold"))
                    Text("买入后卖出模拟")
                        .font(.system(.subheadline, weight: .bold))
                    Spacer()
                }
                .padding(16)

                Divider().padding(.leading, 16)

                inputRow(label: "卖出单价", text: $sellPrice, unit: "¥/g", placeholder: "0.00")

                let sp = Double(sellPrice) ?? 0
                if sp > 0 {
                    let sellResult = GoldCalculator.sell(
                        currentPosition: afterBuy,
                        grams: buyG,
                        pricePerGram: sp
                    )

                    Divider().padding(.leading, 16)

                    HStack {
                        Text("卖出 \(Formatters.gramsString(buyG)) 的盈亏")
                            .font(.system(.subheadline, weight: .bold))
                        Spacer()
                        ProfitText(value: sellResult.transactionProfit, font: .system(.headline, design: .rounded, weight: .bold))
                    }
                    .padding(16)
                    .background(GoldTheme.profitColor(sellResult.transactionProfit).opacity(0.06))

                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Color("BrandGold").opacity(0.6))
                            .font(.system(size: 12))
                        Text("持仓均价已摊薄至 \(Formatters.priceString(afterBuy.averageCost))，盈亏按新均价计算")
                            .font(.system(.caption2, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
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

    private func inputRow(label: String, text: Binding<String>, unit: String, placeholder: String) -> some View {
        HStack {
            Text(label)
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            TextField(placeholder, text: text)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 140)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
            Text(unit)
                .font(.system(.caption, weight: .medium))
                .foregroundStyle(.tertiary)
                .frame(width: 30, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private func resultRow(_ label: String, _ value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(.subheadline, weight: highlight ? .semibold : .medium))
                .foregroundStyle(highlight ? .primary : .secondary)
            Spacer()
            Text(value)
                .font(.system(highlight ? .headline : .subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(highlight ? Color("BrandGold") : .primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        CalculatorView()
    }
}
