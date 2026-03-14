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

    // MARK: - Performance Metrics

    struct PerformanceMetrics {
        let dateRange: ClosedRange<Date>
        let dayCount: Int
        let totalBuyAmount: Double
        let totalSellAmount: Double
        let buyCount: Int
        let sellCount: Int
        let totalBuyGrams: Double
        let totalSellGrams: Double

        /// Position at end of the range (after replaying filtered transactions)
        let endPosition: PositionSnapshot

        /// Current market value of remaining position (0 if no market price)
        let marketValue: Double

        /// Realized profit from sells within the date range
        let realizedProfit: Double
        /// Unrealized profit of remaining position
        let unrealizedProfit: Double
        /// Total P&L = realized + unrealized
        let totalPnL: Double

        /// Net cash invested = totalBuy - totalSell
        let netInvested: Double
        /// Simple return = totalPnL / totalBuyAmount
        let simpleReturn: Double
        /// Annualized return = (1 + simpleReturn)^(365/days) - 1
        let annualizedReturn: Double?
        /// XIRR (Internal Rate of Return) from irregular cash flows — most accurate metric
        let xirr: Double?

        /// Daily average profit
        let dailyAverageProfit: Double
        /// Win rate among sell transactions
        let winRate: Double?
        /// Biggest single winning sell
        let maxWin: Double
        /// Biggest single losing sell
        let maxLoss: Double

        static let empty = PerformanceMetrics(
            dateRange: Date.distantPast...Date.distantFuture,
            dayCount: 0, totalBuyAmount: 0, totalSellAmount: 0,
            buyCount: 0, sellCount: 0, totalBuyGrams: 0, totalSellGrams: 0,
            endPosition: .zero, marketValue: 0,
            realizedProfit: 0, unrealizedProfit: 0, totalPnL: 0,
            netInvested: 0, simpleReturn: 0, annualizedReturn: nil, xirr: nil,
            dailyAverageProfit: 0, winRate: nil, maxWin: 0, maxLoss: 0
        )
    }

    /// Compute comprehensive performance metrics for transactions within a date range.
    /// Transactions before `range.lowerBound` are replayed to establish the starting position.
    static func computeMetrics(
        allTransactions: [ReplayTransaction],
        dateRange: ClosedRange<Date>,
        marketPrice: Double
    ) -> PerformanceMetrics {
        let sorted = allTransactions.sorted { $0.date < $1.date }

        // Split: transactions before range establish the opening position
        let before = sorted.filter { $0.date < dateRange.lowerBound }
        let inRange = sorted.filter { dateRange.contains($0.date) }

        let openingPosition = replayTransactions(before)

        // Replay in-range transactions to get closing position and per-trade stats
        var position = openingPosition
        var realizedProfit = 0.0
        var maxWin = 0.0
        var maxLoss = 0.0
        var winCount = 0
        var sellCount = 0
        var totalBuyAmount = 0.0
        var totalSellAmount = 0.0
        var totalBuyGrams = 0.0
        var totalSellGrams = 0.0
        var buyCount = 0

        for tx in inRange {
            let result: TransactionResult
            switch tx.type {
            case .buy:
                result = buy(currentPosition: position, grams: tx.grams, pricePerGram: tx.pricePerGram)
                totalBuyAmount += tx.grams * tx.pricePerGram
                totalBuyGrams += tx.grams
                buyCount += 1
            case .sell:
                result = sell(currentPosition: position, grams: tx.grams, pricePerGram: tx.pricePerGram)
                let profit = result.transactionProfit
                realizedProfit += profit
                totalSellAmount += tx.grams * tx.pricePerGram
                totalSellGrams += tx.grams
                sellCount += 1
                if profit > 0 { winCount += 1 }
                maxWin = max(maxWin, profit)
                maxLoss = min(maxLoss, profit)
            }
            position = result.newPosition
        }

        let unrealized = marketPrice > 0 ? unrealizedPnL(position: position, marketPrice: marketPrice) : 0
        let mktValue = marketPrice > 0 ? position.totalGrams * marketPrice : 0
        let totalPnL = realizedProfit + unrealized

        let calendar = Calendar.current
        let days = max(1, calendar.dateComponents([.day], from: dateRange.lowerBound, to: dateRange.upperBound).day ?? 1)

        // Capital base: opening position cost + new buys
        let capitalBase = openingPosition.totalCostBasis + totalBuyAmount
        let simpleReturn = capitalBase > 0 ? totalPnL / capitalBase : 0

        var annualized: Double? = nil
        if days >= 7 && capitalBase > 0 {
            let r = 1.0 + simpleReturn
            if r > 0 {
                annualized = pow(r, 365.0 / Double(days)) - 1.0
            }
        }

        // XIRR calculation
        let xirrValue = computeXIRR(
            openingPosition: openingPosition,
            transactions: inRange,
            endMarketPrice: marketPrice,
            dateRange: dateRange
        )

        let winRate: Double? = sellCount > 0 ? Double(winCount) / Double(sellCount) : nil

        return PerformanceMetrics(
            dateRange: dateRange,
            dayCount: days,
            totalBuyAmount: totalBuyAmount,
            totalSellAmount: totalSellAmount,
            buyCount: buyCount,
            sellCount: sellCount,
            totalBuyGrams: totalBuyGrams,
            totalSellGrams: totalSellGrams,
            endPosition: position,
            marketValue: mktValue,
            realizedProfit: realizedProfit,
            unrealizedProfit: unrealized,
            totalPnL: totalPnL,
            netInvested: totalBuyAmount - totalSellAmount,
            simpleReturn: simpleReturn,
            annualizedReturn: annualized,
            xirr: xirrValue,
            dailyAverageProfit: totalPnL / Double(days),
            winRate: winRate,
            maxWin: maxWin,
            maxLoss: maxLoss
        )
    }

    // MARK: - XIRR (Newton's Method)

    /// Cash flow: buy = negative, sell = positive, end position value = positive.
    /// Also includes opening position as a negative cash flow at range start.
    private static func computeXIRR(
        openingPosition: PositionSnapshot,
        transactions: [ReplayTransaction],
        endMarketPrice: Double,
        dateRange: ClosedRange<Date>
    ) -> Double? {
        guard endMarketPrice > 0 else { return nil }

        var cashFlows: [(date: Date, amount: Double)] = []

        // Opening position as initial investment (negative)
        if openingPosition.totalCostBasis > 0 {
            cashFlows.append((dateRange.lowerBound, -openingPosition.totalCostBasis))
        }

        for tx in transactions {
            switch tx.type {
            case .buy:
                cashFlows.append((tx.date, -(tx.grams * tx.pricePerGram)))
            case .sell:
                cashFlows.append((tx.date, tx.grams * tx.pricePerGram))
            }
        }

        // Closing position value as final cash inflow
        var endPosition = openingPosition
        for tx in transactions.sorted(by: { $0.date < $1.date }) {
            switch tx.type {
            case .buy:
                endPosition = buy(currentPosition: endPosition, grams: tx.grams, pricePerGram: tx.pricePerGram).newPosition
            case .sell:
                endPosition = sell(currentPosition: endPosition, grams: tx.grams, pricePerGram: tx.pricePerGram).newPosition
            }
        }
        let endValue = endPosition.totalGrams * endMarketPrice
        if endValue > 0 {
            cashFlows.append((dateRange.upperBound, endValue))
        }

        guard cashFlows.count >= 2 else { return nil }

        let hasNeg = cashFlows.contains { $0.amount < 0 }
        let hasPos = cashFlows.contains { $0.amount > 0 }
        guard hasNeg && hasPos else { return nil }

        let baseDate = cashFlows[0].date
        let yearFractions = cashFlows.map { cf -> (fraction: Double, amount: Double) in
            let days = Calendar.current.dateComponents([.day], from: baseDate, to: cf.date).day ?? 0
            return (Double(days) / 365.0, cf.amount)
        }

        func npv(_ rate: Double) -> Double {
            yearFractions.reduce(0.0) { $0 + $1.amount / pow(1.0 + rate, $1.fraction) }
        }

        func dnpv(_ rate: Double) -> Double {
            yearFractions.reduce(0.0) { $0 - $1.fraction * $1.amount / pow(1.0 + rate, $1.fraction + 1.0) }
        }

        // Newton-Raphson iteration
        var rate = 0.1
        for _ in 0..<200 {
            let f = npv(rate)
            let df = dnpv(rate)
            guard df.isFinite && df != 0 else { break }
            let newRate = rate - f / df
            guard newRate.isFinite && newRate > -1.0 else { break }
            if abs(newRate - rate) < 1e-9 {
                return newRate
            }
            rate = newRate
        }

        // Fallback: bisection if Newton failed
        var lo = -0.99, hi = 10.0
        guard npv(lo) * npv(hi) < 0 else { return nil }
        for _ in 0..<200 {
            let mid = (lo + hi) / 2.0
            if npv(mid) * npv(lo) < 0 { hi = mid } else { lo = mid }
            if hi - lo < 1e-9 { return (lo + hi) / 2.0 }
        }
        return (lo + hi) / 2.0
    }
}
