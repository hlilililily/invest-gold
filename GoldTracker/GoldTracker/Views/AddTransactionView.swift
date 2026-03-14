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

    private var gramsValue: Double { Double(grams) ?? 0 }
    private var priceValue: Double { Double(pricePerGram) ?? 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    typeToggle
                    amountInputCard
                    dateAndNoteCard
                    if transactionType == .sell { positionInfo }
                    if gramsValue > 0 && priceValue > 0 { previewCard }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("添加交易")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        submitTransaction()
                    } label: {
                        Text("确认")
                            .font(.system(.body, weight: .bold))
                            .foregroundStyle(isValid ? Color("BrandGold") : .secondary)
                    }
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

    // MARK: - Type Toggle

    private var typeToggle: some View {
        HStack(spacing: 0) {
            ForEach(TransactionType.allCases, id: \.self) { type in
                let selected = transactionType == type
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        transactionType = type
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: type == .buy ? "arrow.down.left" : "arrow.up.right")
                            .font(.system(size: 13, weight: .bold))
                        Text(type.rawValue)
                            .font(.system(.subheadline, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background {
                        if selected {
                            RoundedRectangle(cornerRadius: GoldTheme.buttonRadius, style: .continuous)
                                .fill(type == .buy ? Color(hex: 0xF5A623) : Color(hex: 0x2196F3))
                        }
                    }
                    .foregroundStyle(selected ? .white : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: GoldTheme.innerRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        }
    }

    // MARK: - Amount Input

    private var amountInputCard: some View {
        VStack(spacing: 0) {
            VStack(alignment: .center, spacing: 6) {
                Text("数量")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    TextField("0", text: $grams)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    Text("g")
                        .font(.system(.title2, design: .rounded, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 20)

            Divider()

            VStack(alignment: .center, spacing: 6) {
                Text("单价")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("¥")
                        .font(.system(.title2, design: .rounded, weight: .medium))
                        .foregroundStyle(.tertiary)
                    TextField("0.00", text: $pricePerGram)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    Text("/g")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 20)

            if gramsValue > 0 && priceValue > 0 {
                Divider()
                HStack {
                    Text("交易金额")
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(Formatters.priceString(gramsValue * priceValue))
                        .font(.system(.headline, design: .rounded, weight: .bold))
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

    // MARK: - Date & Note

    private var dateAndNoteCard: some View {
        VStack(spacing: 0) {
            DatePicker("交易日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .font(.system(.subheadline, weight: .medium))
                .padding(16)

            Divider().padding(.leading, 16)

            HStack {
                Image(systemName: "note.text")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 14))
                TextField("添加备注（选填）", text: $note)
                    .font(.subheadline)
            }
            .padding(16)
        }
        .background {
            RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        }
    }

    // MARK: - Position Info

    private var positionInfo: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Color("BrandGold"))
            VStack(alignment: .leading, spacing: 2) {
                Text("当前持仓 \(Formatters.gramsString(viewModel.holdingGrams))")
                    .font(.system(.subheadline, weight: .semibold))
                Text("持仓均价 \(Formatters.priceString(viewModel.averageCost))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: GoldTheme.innerRadius, style: .continuous)
                .fill(Color("BrandGold").opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: GoldTheme.innerRadius, style: .continuous)
                        .stroke(Color("BrandGold").opacity(0.2), lineWidth: 1)
                }
        }
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("交易预览")
                    .font(.system(.subheadline, weight: .bold))
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundStyle(Color("BrandGold"))
            }
            .padding(16)

            Divider().padding(.leading, 16)

            if transactionType == .buy {
                let result = GoldCalculator.buy(
                    currentPosition: currentSnapshot,
                    grams: gramsValue,
                    pricePerGram: priceValue
                )
                previewRow("买入后均价", Formatters.priceString(result.newPosition.averageCost))
                Divider().padding(.leading, 16)
                previewRow("买入后持仓", Formatters.gramsString(result.newPosition.totalGrams))
            } else {
                let result = GoldCalculator.sell(
                    currentPosition: currentSnapshot,
                    grams: min(gramsValue, viewModel.holdingGrams),
                    pricePerGram: priceValue
                )
                HStack {
                    Text("本次盈亏")
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    ProfitText(value: result.transactionProfit, font: .system(.headline, design: .rounded, weight: .bold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider().padding(.leading, 16)
                previewRow("卖出后持仓", Formatters.gramsString(result.newPosition.totalGrams))
                if result.newPosition.totalGrams > 0 {
                    Divider().padding(.leading, 16)
                    previewRow("卖出后均价", Formatters.priceString(result.newPosition.averageCost))
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: GoldTheme.cardRadius, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        }
    }

    private func previewRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
        guard gramsValue > 0, priceValue > 0 else { return false }
        if transactionType == .sell && gramsValue > viewModel.holdingGrams { return false }
        return true
    }

    private func submitTransaction() {
        if transactionType == .sell && gramsValue > viewModel.holdingGrams {
            errorMessage = "卖出数量不能超过持仓 (\(Formatters.gramsString(viewModel.holdingGrams)))"
            showError = true
            return
        }

        switch transactionType {
        case .buy:
            viewModel.addBuyTransaction(grams: gramsValue, pricePerGram: priceValue, date: date, note: note)
        case .sell:
            viewModel.addSellTransaction(grams: gramsValue, pricePerGram: priceValue, date: date, note: note)
        }

        dismiss()
    }
}
