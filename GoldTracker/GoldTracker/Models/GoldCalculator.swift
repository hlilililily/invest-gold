import Foundation

/// Core calculation engine using the Weighted Average Cost (WAC) method.
///
/// WAC rules:
/// - **Buy**: new avg = (held_qty × old_avg + buy_qty × buy_price) / (held_qty + buy_qty)
/// - **Sell**: realized P&L = (sell_price − current_avg) × sell_qty; avg cost unchanged
/// - **Unrealized P&L**: (market_price − avg_cost) × held_qty
struct GoldCalculator {

    struct PositionSnapshot {
        let totalGrams: Double
        let averageCost: Double
        let totalCostBasis: Double
        let realizedProfit: Double

        static let zero = PositionSnapshot(totalGrams: 0, averageCost: 0, totalCostBasis: 0, realizedProfit: 0)
    }

    struct TransactionResult {
        let newPosition: PositionSnapshot
        let transactionProfit: Double
    }

    // MARK: - Buy

    static func buy(
        currentPosition: PositionSnapshot,
        grams: Double,
        pricePerGram: Double
    ) -> TransactionResult {
        guard grams > 0, pricePerGram > 0 else {
            return TransactionResult(newPosition: currentPosition, transactionProfit: 0)
        }

        let oldTotalCost = currentPosition.totalGrams * currentPosition.averageCost
        let purchaseCost = grams * pricePerGram
        let newTotalGrams = currentPosition.totalGrams + grams
        let newAverageCost = newTotalGrams > 0 ? (oldTotalCost + purchaseCost) / newTotalGrams : 0

        let newPosition = PositionSnapshot(
            totalGrams: newTotalGrams,
            averageCost: newAverageCost,
            totalCostBasis: newTotalGrams * newAverageCost,
            realizedProfit: currentPosition.realizedProfit
        )

        return TransactionResult(newPosition: newPosition, transactionProfit: 0)
    }

    // MARK: - Sell

    static func sell(
        currentPosition: PositionSnapshot,
        grams: Double,
        pricePerGram: Double
    ) -> TransactionResult {
        guard grams > 0, pricePerGram > 0 else {
            return TransactionResult(newPosition: currentPosition, transactionProfit: 0)
        }

        let sellGrams = min(grams, currentPosition.totalGrams)
        let profit = (pricePerGram - currentPosition.averageCost) * sellGrams
        let newTotalGrams = currentPosition.totalGrams - sellGrams

        let newPosition = PositionSnapshot(
            totalGrams: newTotalGrams,
            averageCost: newTotalGrams > 0 ? currentPosition.averageCost : 0,
            totalCostBasis: newTotalGrams * currentPosition.averageCost,
            realizedProfit: currentPosition.realizedProfit + profit
        )

        return TransactionResult(newPosition: newPosition, transactionProfit: profit)
    }

    // MARK: - Unrealized P&L

    static func unrealizedPnL(position: PositionSnapshot, marketPrice: Double) -> Double {
        guard position.totalGrams > 0 else { return 0 }
        return (marketPrice - position.averageCost) * position.totalGrams
    }

    // MARK: - Replay All Transactions

    /// Replays a chronologically-sorted list of transactions to rebuild the position.
    static func replayTransactions(_ transactions: [ReplayTransaction]) -> PositionSnapshot {
        var position = PositionSnapshot.zero

        for tx in transactions.sorted(by: { $0.date < $1.date }) {
            let result: TransactionResult
            switch tx.type {
            case .buy:
                result = buy(currentPosition: position, grams: tx.grams, pricePerGram: tx.pricePerGram)
            case .sell:
                result = sell(currentPosition: position, grams: tx.grams, pricePerGram: tx.pricePerGram)
            }
            position = result.newPosition
        }

        return position
    }

    struct ReplayTransaction {
        let type: TransactionType
        let grams: Double
        let pricePerGram: Double
        let date: Date
    }
}
