import SwiftUI

struct AddTransactionView: View {
    @Environment(PortfolioViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var transactionType: TransactionType = .buy
    @State private var grams: String = ""
    @State private var pricePerGram: String = ""
    @State private var date: Date = .now
    @State private var note: String = ""
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                transactionTypeSection
                detailsSection
                previewSection
            }
            .navigationTitle("添加交易")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确认") { submitTransaction() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Type Selection

    private var transactionTypeSection: some View {
        Section {
            Picker("交易类型", selection: $transactionType) {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Text("策略分组")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(viewModel.selectedPortfolioName)
                    .fontWeight(.medium)
            }
        }
    }

    // MARK: - Details

    private var detailsSection: some View {
        Section("交易详情") {
            HStack {
                Text("克数")
                Spacer()
                TextField("0", text: $grams)
                    .multilineTextAlignment(.trailing)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                Text("g")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("单价")
                Spacer()
                TextField("0.00", text: $pricePerGram)
                    .multilineTextAlignment(.trailing)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                Text("¥/g")
                    .foregroundStyle(.secondary)
            }

            DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])

            TextField("备注（选填）", text: $note)

            if transactionType == .sell {
                HStack {
                    Text("当前持仓")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(Formatters.gramsString(viewModel.holdingGrams))
                    Text("均价 \(Formatters.priceString(viewModel.averageCost))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        let gramsValue = Double(grams) ?? 0
        let priceValue = Double(pricePerGram) ?? 0

        return Group {
            if gramsValue > 0 && priceValue > 0 {
                Section("交易预览") {
                    HStack {
                        Text("交易金额")
                        Spacer()
                        Text(Formatters.priceString(gramsValue * priceValue))
                            .fontWeight(.medium)
                    }

                    if transactionType == .buy {
                        let result = GoldCalculator.buy(
                            currentPosition: currentSnapshot,
                            grams: gramsValue,
                            pricePerGram: priceValue
                        )
                        HStack {
                            Text("买入后均价")
                            Spacer()
                            Text(Formatters.priceString(result.newPosition.averageCost))
                                .fontWeight(.medium)
                        }
                        HStack {
                            Text("买入后持仓")
                            Spacer()
                            Text(Formatters.gramsString(result.newPosition.totalGrams))
                                .fontWeight(.medium)
                        }
                    } else {
                        let result = GoldCalculator.sell(
                            currentPosition: currentSnapshot,
                            grams: min(gramsValue, viewModel.holdingGrams),
                            pricePerGram: priceValue
                        )
                        HStack {
                            Text("本次盈亏")
                            Spacer()
                            ProfitText(value: result.transactionProfit, font: .body.weight(.semibold))
                        }
                        HStack {
                            Text("卖出后持仓")
                            Spacer()
                            Text(Formatters.gramsString(result.newPosition.totalGrams))
                                .fontWeight(.medium)
                        }
                        if result.newPosition.totalGrams > 0 {
                            HStack {
                                Text("卖出后均价")
                                Spacer()
                                Text(Formatters.priceString(result.newPosition.averageCost))
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Logic

    private var currentSnapshot: GoldCalculator.PositionSnapshot {
        GoldCalculator.PositionSnapshot(
            totalGrams: viewModel.holdingGrams,
            averageCost: viewModel.averageCost,
            totalCostBasis: viewModel.totalCostBasis,
            realizedProfit: viewModel.totalRealizedProfit
        )
    }

    private var isValid: Bool {
        guard let g = Double(grams), g > 0 else { return false }
        guard let p = Double(pricePerGram), p > 0 else { return false }
        if transactionType == .sell && g > viewModel.holdingGrams { return false }
        return true
    }

    private func submitTransaction() {
        guard let g = Double(grams), let p = Double(pricePerGram) else { return }

        if transactionType == .sell && g > viewModel.holdingGrams {
            errorMessage = "卖出克数不能超过持仓(\(Formatters.gramsString(viewModel.holdingGrams)))"
            showError = true
            return
        }

        switch transactionType {
        case .buy:
            viewModel.addBuyTransaction(grams: g, pricePerGram: p, date: date, note: note)
        case .sell:
            viewModel.addSellTransaction(grams: g, pricePerGram: p, date: date, note: note)
        }

        dismiss()
    }
}
