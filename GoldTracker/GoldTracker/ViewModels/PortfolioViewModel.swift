import Foundation
import SwiftData
import SwiftUI

@MainActor @Observable
final class PortfolioViewModel {
    var portfolios: [Portfolio] = []
    var transactions: [Transaction] = []
    var selectedPortfolioName: String = "默认"
    var currentMarketPrice: Double = 0

    private var modelContext: ModelContext?

    var currentPortfolio: Portfolio? {
        portfolios.first { $0.name == selectedPortfolioName }
    }

    var filteredTransactions: [Transaction] {
        transactions
            .filter { $0.portfolioName == selectedPortfolioName }
            .sorted { $0.date > $1.date }
    }

    var allPortfolioNames: [String] {
        let names = Set(portfolios.map(\.name))
        return Array(names).sorted()
    }

    // MARK: - Derived Stats

    var holdingGrams: Double {
        currentPortfolio?.totalGrams ?? 0
    }

    var averageCost: Double {
        currentPortfolio?.averageCost ?? 0
    }

    var totalCostBasis: Double {
        holdingGrams * averageCost
    }

    var totalMarketValue: Double {
        holdingGrams * currentMarketPrice
    }

    var unrealizedPnL: Double {
        guard holdingGrams > 0 else { return 0 }
        return GoldCalculator.unrealizedPnL(
            position: currentPositionSnapshot,
            marketPrice: currentMarketPrice
        )
    }

    var unrealizedPnLPercent: Double {
        guard totalCostBasis > 0 else { return 0 }
        return unrealizedPnL / totalCostBasis
    }

    var totalRealizedProfit: Double {
        currentPortfolio?.totalRealizedProfit ?? 0
    }

    var totalPnL: Double {
        totalRealizedProfit + unrealizedPnL
    }

    var totalInvested: Double {
        currentPortfolio?.totalInvested ?? 0
    }

    private var currentPositionSnapshot: GoldCalculator.PositionSnapshot {
        GoldCalculator.PositionSnapshot(
            totalGrams: holdingGrams,
            averageCost: averageCost,
            totalCostBasis: totalCostBasis,
            realizedProfit: totalRealizedProfit
        )
    }

    // MARK: - Setup

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchAll()
    }

    func fetchAll() {
        guard let modelContext else { return }

        let portfolioDescriptor = FetchDescriptor<Portfolio>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        let transactionDescriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            portfolios = try modelContext.fetch(portfolioDescriptor)
            transactions = try modelContext.fetch(transactionDescriptor)

            if portfolios.isEmpty {
                let defaultPortfolio = Portfolio(name: "默认")
                modelContext.insert(defaultPortfolio)
                let longTermPortfolio = Portfolio(name: "长线")
                modelContext.insert(longTermPortfolio)
                let shortTermPortfolio = Portfolio(name: "短线")
                modelContext.insert(shortTermPortfolio)
                try modelContext.save()
                portfolios = [defaultPortfolio, longTermPortfolio, shortTermPortfolio]
                selectedPortfolioName = "默认"
            }
        } catch {
            print("Fetch failed: \(error)")
        }
    }

    // MARK: - Transactions

    func addBuyTransaction(grams: Double, pricePerGram: Double, date: Date, note: String) {
        guard let modelContext, let portfolio = currentPortfolio else { return }

        let result = GoldCalculator.buy(
            currentPosition: currentPositionSnapshot,
            grams: grams,
            pricePerGram: pricePerGram
        )

        let transaction = Transaction(
            type: .buy,
            grams: grams,
            pricePerGram: pricePerGram,
            date: date,
            note: note,
            portfolioName: selectedPortfolioName,
            averageCostAtTransaction: result.newPosition.averageCost,
            realizedProfit: 0
        )

        portfolio.totalGrams = result.newPosition.totalGrams
        portfolio.averageCost = result.newPosition.averageCost
        portfolio.totalInvested += grams * pricePerGram

        modelContext.insert(transaction)
        saveAndRefresh()
    }

    func addSellTransaction(grams: Double, pricePerGram: Double, date: Date, note: String) {
        guard let modelContext, let portfolio = currentPortfolio else { return }
        guard grams <= portfolio.totalGrams else { return }

        let result = GoldCalculator.sell(
            currentPosition: currentPositionSnapshot,
            grams: grams,
            pricePerGram: pricePerGram
        )

        let transaction = Transaction(
            type: .sell,
            grams: grams,
            pricePerGram: pricePerGram,
            date: date,
            note: note,
            portfolioName: selectedPortfolioName,
            averageCostAtTransaction: averageCost,
            realizedProfit: result.transactionProfit
        )

        portfolio.totalGrams = result.newPosition.totalGrams
        portfolio.averageCost = result.newPosition.averageCost
        portfolio.totalRealizedProfit = result.newPosition.realizedProfit

        modelContext.insert(transaction)
        saveAndRefresh()
    }

    func deleteTransaction(_ transaction: Transaction) {
        guard let modelContext else { return }
        modelContext.delete(transaction)
        saveAndRefresh()
        recalculatePortfolio()
    }

    // MARK: - Portfolio Management

    func addPortfolio(name: String) {
        guard let modelContext else { return }
        guard !name.isEmpty, !portfolios.contains(where: { $0.name == name }) else { return }

        let portfolio = Portfolio(name: name)
        modelContext.insert(portfolio)
        saveAndRefresh()
        selectedPortfolioName = name
    }

    func deletePortfolio(_ portfolio: Portfolio) {
        guard let modelContext else { return }
        let name = portfolio.name
        let txToDelete = transactions.filter { $0.portfolioName == name }
        txToDelete.forEach { modelContext.delete($0) }
        modelContext.delete(portfolio)

        if selectedPortfolioName == name {
            selectedPortfolioName = portfolios.first(where: { $0.name != name })?.name ?? "默认"
        }
        saveAndRefresh()
    }

    /// Rebuilds portfolio state from transaction history (used after deleting a transaction)
    func recalculatePortfolio() {
        guard let portfolio = currentPortfolio else { return }

        let relevantTransactions = transactions
            .filter { $0.portfolioName == selectedPortfolioName }
            .sorted { $0.date < $1.date }

        let replayData = relevantTransactions.map {
            GoldCalculator.ReplayTransaction(
                type: $0.type,
                grams: $0.grams,
                pricePerGram: $0.pricePerGram,
                date: $0.date
            )
        }

        let position = GoldCalculator.replayTransactions(replayData)
        portfolio.totalGrams = position.totalGrams
        portfolio.averageCost = position.averageCost
        portfolio.totalRealizedProfit = position.realizedProfit
        portfolio.totalInvested = relevantTransactions
            .filter { $0.type == .buy }
            .reduce(0.0) { $0 + $1.totalAmount }

        saveAndRefresh()
    }

    // MARK: - Helpers

    private func saveAndRefresh() {
        guard let modelContext else { return }
        do {
            try modelContext.save()
            fetchAll()
        } catch {
            print("Save failed: \(error)")
        }
    }

    // MARK: - Summary across all portfolios

    var allPortfoliosSummary: (grams: Double, costBasis: Double, realized: Double, invested: Double) {
        let grams = portfolios.reduce(0.0) { $0 + $1.totalGrams }
        let costBasis = portfolios.reduce(0.0) { $0 + $1.totalGrams * $1.averageCost }
        let realized = portfolios.reduce(0.0) { $0 + $1.totalRealizedProfit }
        let invested = portfolios.reduce(0.0) { $0 + $1.totalInvested }
        return (grams, costBasis, realized, invested)
    }

    func unrealizedPnLForPortfolio(_ portfolio: Portfolio) -> Double {
        guard portfolio.totalGrams > 0, currentMarketPrice > 0 else { return 0 }
        return (currentMarketPrice - portfolio.averageCost) * portfolio.totalGrams
    }

    // MARK: - Analytics

    func computeMetrics(dateRange: ClosedRange<Date>) -> GoldCalculator.PerformanceMetrics {
        let replayData = filteredTransactions.map {
            GoldCalculator.ReplayTransaction(
                type: $0.type,
                grams: $0.grams,
                pricePerGram: $0.pricePerGram,
                date: $0.date
            )
        }
        return GoldCalculator.computeMetrics(
            allTransactions: replayData,
            dateRange: dateRange,
            marketPrice: currentMarketPrice
        )
    }

    /// Earliest transaction date in the current portfolio
    var earliestTransactionDate: Date? {
        filteredTransactions.last?.date
    }
}
