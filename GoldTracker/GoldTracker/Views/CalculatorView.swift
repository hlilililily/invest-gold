import SwiftUI

/// Standalone calculator for "what if" scenarios without recording transactions.
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
        Form {
            Section("当前持仓") {
                HStack {
                    Text("持仓克数")
                    Spacer()
                    TextField("0", text: $holdingGrams)
                        .multilineTextAlignment(.trailing)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    Text("g")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("持仓均价")
                    Spacer()
                    TextField("0.00", text: $holdingAvgCost)
                        .multilineTextAlignment(.trailing)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    Text("¥/g")
                        .foregroundStyle(.secondary)
                }

                if currentPosition.totalGrams > 0 {
                    HStack {
                        Text("持仓成本")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(Formatters.priceString(currentPosition.totalCostBasis))
                    }
                }
            }

            Section("模拟操作") {
                Picker("操作类型", selection: $actionType) {
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Text(actionType == .buy ? "买入克数" : "卖出克数")
                    Spacer()
                    TextField("0", text: $actionGrams)
                        .multilineTextAlignment(.trailing)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    Text("g")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text(actionType == .buy ? "买入单价" : "卖出单价")
                    Spacer()
                    TextField("0.00", text: $actionPrice)
                        .multilineTextAlignment(.trailing)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    Text("¥/g")
                        .foregroundStyle(.secondary)
                }
            }

            resultSection

            if actionType == .buy {
                sellSimulationSection
            }
        }
        .navigationTitle("收益计算器")
    }

    // MARK: - Result

    @ViewBuilder
    private var resultSection: some View {
        let g = Double(actionGrams) ?? 0
        let p = Double(actionPrice) ?? 0

        if g > 0 && p > 0 && currentPosition.totalGrams > 0 {
            Section("计算结果") {
                switch actionType {
                case .buy:
                    let result = GoldCalculator.buy(
                        currentPosition: currentPosition,
                        grams: g,
                        pricePerGram: p
                    )
                    row("交易金额", Formatters.priceString(g * p))
                    row("新持仓", Formatters.gramsString(result.newPosition.totalGrams))
                    row("新均价", Formatters.priceString(result.newPosition.averageCost))
                    row("新成本", Formatters.priceString(result.newPosition.totalCostBasis))

                case .sell:
                    let sellGrams = min(g, currentPosition.totalGrams)
                    let result = GoldCalculator.sell(
                        currentPosition: currentPosition,
                        grams: sellGrams,
                        pricePerGram: p
                    )
                    row("交易金额", Formatters.priceString(sellGrams * p))
                    row("成本价", Formatters.priceString(currentPosition.averageCost))
                    HStack {
                        Text("本次盈亏")
                        Spacer()
                        ProfitText(value: result.transactionProfit, font: .body.weight(.semibold))
                    }
                    row("剩余持仓", Formatters.gramsString(result.newPosition.totalGrams))
                    if result.newPosition.totalGrams > 0 {
                        row("剩余均价", Formatters.priceString(result.newPosition.averageCost))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var sellSimulationSection: some View {
        let buyG = Double(actionGrams) ?? 0
        let buyP = Double(actionPrice) ?? 0

        if buyG > 0 && buyP > 0 && currentPosition.totalGrams > 0 {
            let afterBuy = GoldCalculator.buy(
                currentPosition: currentPosition,
                grams: buyG,
                pricePerGram: buyP
            ).newPosition

            Section("买入后卖出模拟") {
                HStack {
                    Text("卖出单价")
                    Spacer()
                    TextField("0.00", text: $sellPrice)
                        .multilineTextAlignment(.trailing)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    Text("¥/g")
                        .foregroundStyle(.secondary)
                }

                let sp = Double(sellPrice) ?? 0
                if sp > 0 {
                    let sellResult = GoldCalculator.sell(
                        currentPosition: afterBuy,
                        grams: buyG,
                        pricePerGram: sp
                    )

                    HStack {
                        Text("卖出 \(Formatters.gramsString(buyG)) 的盈亏")
                            .foregroundStyle(.secondary)
                        Spacer()
                        ProfitText(value: sellResult.transactionProfit, font: .body.weight(.semibold))
                    }

                    Text("注：因持仓均价已摊薄至 \(Formatters.priceString(afterBuy.averageCost))，所以盈亏按新均价计算")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        CalculatorView()
    }
}
