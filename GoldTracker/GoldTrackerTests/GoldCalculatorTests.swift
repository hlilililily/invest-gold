import XCTest
@testable import GoldTracker

final class GoldCalculatorTests: XCTestCase {
    let epsilon = 0.01

    // MARK: - Buy Tests

    func testBuyFromZero() {
        let result = GoldCalculator.buy(
            currentPosition: .zero,
            grams: 100,
            pricePerGram: 1100
        )

        XCTAssertEqual(result.newPosition.totalGrams, 100)
        XCTAssertEqual(result.newPosition.averageCost, 1100, accuracy: epsilon)
        XCTAssertEqual(result.transactionProfit, 0)
    }

    func testBuyDilutesAverage() {
        let initial = GoldCalculator.PositionSnapshot(
            totalGrams: 100, averageCost: 1100, totalCostBasis: 110_000, realizedProfit: 0
        )

        let result = GoldCalculator.buy(
            currentPosition: initial,
            grams: 10,
            pricePerGram: 1000
        )

        // (100*1100 + 10*1000) / 110 = 120_000 / 110 ≈ 1090.91
        XCTAssertEqual(result.newPosition.totalGrams, 110)
        XCTAssertEqual(result.newPosition.averageCost, 1090.91, accuracy: epsilon)
        XCTAssertEqual(result.transactionProfit, 0)
    }

    func testBuyIncreasesAverage() {
        let initial = GoldCalculator.PositionSnapshot(
            totalGrams: 50, averageCost: 1000, totalCostBasis: 50_000, realizedProfit: 0
        )

        let result = GoldCalculator.buy(
            currentPosition: initial,
            grams: 50,
            pricePerGram: 1200
        )

        // (50*1000 + 50*1200) / 100 = 110_000 / 100 = 1100
        XCTAssertEqual(result.newPosition.totalGrams, 100)
        XCTAssertEqual(result.newPosition.averageCost, 1100, accuracy: epsilon)
    }

    // MARK: - Sell Tests

    func testSellWithProfit() {
        let initial = GoldCalculator.PositionSnapshot(
            totalGrams: 100, averageCost: 1000, totalCostBasis: 100_000, realizedProfit: 0
        )

        let result = GoldCalculator.sell(
            currentPosition: initial,
            grams: 20,
            pricePerGram: 1200
        )

        // profit = (1200 - 1000) * 20 = 4000
        XCTAssertEqual(result.transactionProfit, 4000, accuracy: epsilon)
        XCTAssertEqual(result.newPosition.totalGrams, 80)
        XCTAssertEqual(result.newPosition.averageCost, 1000, accuracy: epsilon)
    }

    func testSellWithLoss() {
        let initial = GoldCalculator.PositionSnapshot(
            totalGrams: 100, averageCost: 1100, totalCostBasis: 110_000, realizedProfit: 0
        )

        let result = GoldCalculator.sell(
            currentPosition: initial,
            grams: 30,
            pricePerGram: 1000
        )

        // profit = (1000 - 1100) * 30 = -3000
        XCTAssertEqual(result.transactionProfit, -3000, accuracy: epsilon)
        XCTAssertEqual(result.newPosition.totalGrams, 70)
        XCTAssertEqual(result.newPosition.averageCost, 1100, accuracy: epsilon)
    }

    func testSellAllClearsPosition() {
        let initial = GoldCalculator.PositionSnapshot(
            totalGrams: 50, averageCost: 1050, totalCostBasis: 52_500, realizedProfit: 500
        )

        let result = GoldCalculator.sell(
            currentPosition: initial,
            grams: 50,
            pricePerGram: 1100
        )

        // profit = (1100 - 1050) * 50 = 2500, cumulative = 500 + 2500 = 3000
        XCTAssertEqual(result.transactionProfit, 2500, accuracy: epsilon)
        XCTAssertEqual(result.newPosition.totalGrams, 0)
        XCTAssertEqual(result.newPosition.averageCost, 0)
        XCTAssertEqual(result.newPosition.realizedProfit, 3000, accuracy: epsilon)
    }

    // MARK: - User's Exact Scenario

    func testUserScenario_BuyThenSellWithDilutedAverage() {
        // Step 1: Hold 100g at avg 1100
        let initial = GoldCalculator.PositionSnapshot(
            totalGrams: 100, averageCost: 1100, totalCostBasis: 110_000, realizedProfit: 0
        )

        // Step 2: Buy 10g at 1000
        let afterBuy = GoldCalculator.buy(
            currentPosition: initial,
            grams: 10,
            pricePerGram: 1000
        )

        // New avg = (100*1100 + 10*1000) / 110 = 120000/110 ≈ 1090.91
        XCTAssertEqual(afterBuy.newPosition.totalGrams, 110)
        XCTAssertEqual(afterBuy.newPosition.averageCost, 1090.91, accuracy: epsilon)

        // Step 3: Sell 10g at 1100
        let afterSell = GoldCalculator.sell(
            currentPosition: afterBuy.newPosition,
            grams: 10,
            pricePerGram: 1100
        )

        // Profit = (1100 - 1090.91) * 10 ≈ 90.91 (NOT 1000!)
        XCTAssertEqual(afterSell.transactionProfit, 90.91, accuracy: epsilon)
        XCTAssertEqual(afterSell.newPosition.totalGrams, 100)
        XCTAssertEqual(afterSell.newPosition.averageCost, 1090.91, accuracy: epsilon)
    }

    // MARK: - Unrealized P&L

    func testUnrealizedPnL() {
        let position = GoldCalculator.PositionSnapshot(
            totalGrams: 100, averageCost: 1000, totalCostBasis: 100_000, realizedProfit: 0
        )

        let pnl = GoldCalculator.unrealizedPnL(position: position, marketPrice: 1150)
        // (1150 - 1000) * 100 = 15000
        XCTAssertEqual(pnl, 15_000, accuracy: epsilon)
    }

    func testUnrealizedPnLNegative() {
        let position = GoldCalculator.PositionSnapshot(
            totalGrams: 50, averageCost: 1200, totalCostBasis: 60_000, realizedProfit: 0
        )

        let pnl = GoldCalculator.unrealizedPnL(position: position, marketPrice: 1100)
        // (1100 - 1200) * 50 = -5000
        XCTAssertEqual(pnl, -5_000, accuracy: epsilon)
    }

    // MARK: - Replay

    func testReplayTransactions() {
        let now = Date()
        let transactions: [GoldCalculator.ReplayTransaction] = [
            .init(type: .buy, grams: 100, pricePerGram: 1000, date: now),
            .init(type: .buy, grams: 50, pricePerGram: 1100, date: now.addingTimeInterval(3600)),
            .init(type: .sell, grams: 30, pricePerGram: 1200, date: now.addingTimeInterval(7200)),
        ]

        let position = GoldCalculator.replayTransactions(transactions)

        // After buy 100@1000: avg=1000, qty=100
        // After buy 50@1100: avg=(100000+55000)/150=1033.33, qty=150
        // After sell 30@1200: profit=(1200-1033.33)*30=5000, qty=120, avg=1033.33
        XCTAssertEqual(position.totalGrams, 120, accuracy: epsilon)
        XCTAssertEqual(position.averageCost, 1033.33, accuracy: epsilon)
        XCTAssertEqual(position.realizedProfit, 5000, accuracy: epsilon)
    }

    // MARK: - Edge Cases

    func testBuyWithZeroGrams() {
        let initial = GoldCalculator.PositionSnapshot(
            totalGrams: 100, averageCost: 1000, totalCostBasis: 100_000, realizedProfit: 0
        )
        let result = GoldCalculator.buy(currentPosition: initial, grams: 0, pricePerGram: 1100)
        XCTAssertEqual(result.newPosition.totalGrams, initial.totalGrams)
        XCTAssertEqual(result.newPosition.averageCost, initial.averageCost)
    }

    func testSellMoreThanHeld() {
        let initial = GoldCalculator.PositionSnapshot(
            totalGrams: 10, averageCost: 1000, totalCostBasis: 10_000, realizedProfit: 0
        )
        let result = GoldCalculator.sell(currentPosition: initial, grams: 50, pricePerGram: 1100)
        XCTAssertEqual(result.newPosition.totalGrams, 0)
        XCTAssertEqual(result.transactionProfit, 1000, accuracy: epsilon) // (1100-1000)*10
    }

    // MARK: - Multi-step Short-term Trading

    func testShortTermTradingScenario() {
        // Simulate: buy low, sell high, buy again, sell again
        var position = GoldCalculator.PositionSnapshot.zero

        // Buy 50g @ 980
        let r1 = GoldCalculator.buy(currentPosition: position, grams: 50, pricePerGram: 980)
        position = r1.newPosition
        XCTAssertEqual(position.averageCost, 980)

        // Price goes up, sell 20g @ 1050
        let r2 = GoldCalculator.sell(currentPosition: position, grams: 20, pricePerGram: 1050)
        position = r2.newPosition
        // profit = (1050-980)*20 = 1400
        XCTAssertEqual(r2.transactionProfit, 1400, accuracy: epsilon)
        XCTAssertEqual(position.totalGrams, 30)
        XCTAssertEqual(position.averageCost, 980) // unchanged

        // Price drops, buy 40g @ 950
        let r3 = GoldCalculator.buy(currentPosition: position, grams: 40, pricePerGram: 950)
        position = r3.newPosition
        // new avg = (30*980 + 40*950) / 70 = (29400+38000)/70 = 962.86
        XCTAssertEqual(position.averageCost, 962.86, accuracy: epsilon)
        XCTAssertEqual(position.totalGrams, 70)

        // Sell all @ 1000
        let r4 = GoldCalculator.sell(currentPosition: position, grams: 70, pricePerGram: 1000)
        position = r4.newPosition
        // profit = (1000-962.86)*70 = 2600
        XCTAssertEqual(r4.transactionProfit, 2600, accuracy: epsilon)
        XCTAssertEqual(position.totalGrams, 0)
        // total realized = 1400 + 2600 = 4000
        XCTAssertEqual(position.realizedProfit, 4000, accuracy: epsilon)
    }

    // MARK: - Performance Metrics

    func testMetrics_BasicBuyAndHold() {
        let start = Date(timeIntervalSince1970: 0) // 1970-01-01
        let end = start.addingTimeInterval(365 * 86400) // 1 year later

        let transactions: [GoldCalculator.ReplayTransaction] = [
            .init(type: .buy, grams: 100, pricePerGram: 1000, date: start.addingTimeInterval(86400)),
        ]

        let metrics = GoldCalculator.computeMetrics(
            allTransactions: transactions,
            dateRange: start...end,
            marketPrice: 1100
        )

        XCTAssertEqual(metrics.totalBuyAmount, 100_000, accuracy: epsilon)
        XCTAssertEqual(metrics.buyCount, 1)
        XCTAssertEqual(metrics.sellCount, 0)
        XCTAssertEqual(metrics.realizedProfit, 0, accuracy: epsilon)
        // unrealized = (1100 - 1000) * 100 = 10000
        XCTAssertEqual(metrics.unrealizedProfit, 10_000, accuracy: epsilon)
        XCTAssertEqual(metrics.totalPnL, 10_000, accuracy: epsilon)
        // simple return = 10000 / 100000 = 0.10
        XCTAssertEqual(metrics.simpleReturn, 0.10, accuracy: epsilon)
    }

    func testMetrics_BuySellCycle() {
        let start = Date(timeIntervalSince1970: 0)
        let end = start.addingTimeInterval(180 * 86400) // 180 days

        let transactions: [GoldCalculator.ReplayTransaction] = [
            .init(type: .buy, grams: 100, pricePerGram: 1000, date: start.addingTimeInterval(86400)),
            .init(type: .sell, grams: 50, pricePerGram: 1200, date: start.addingTimeInterval(90 * 86400)),
        ]

        let metrics = GoldCalculator.computeMetrics(
            allTransactions: transactions,
            dateRange: start...end,
            marketPrice: 1100
        )

        XCTAssertEqual(metrics.buyCount, 1)
        XCTAssertEqual(metrics.sellCount, 1)
        // realized = (1200-1000)*50 = 10000
        XCTAssertEqual(metrics.realizedProfit, 10_000, accuracy: epsilon)
        // unrealized = (1100-1000)*50 = 5000
        XCTAssertEqual(metrics.unrealizedProfit, 5_000, accuracy: epsilon)
        XCTAssertEqual(metrics.totalPnL, 15_000, accuracy: epsilon)

        XCTAssertEqual(metrics.netInvested, 100_000 - 60_000, accuracy: epsilon)

        // win rate = 1/1 = 100%
        XCTAssertEqual(metrics.winRate, 1.0, accuracy: epsilon)
        XCTAssertEqual(metrics.maxWin, 10_000, accuracy: epsilon)
    }

    func testMetrics_DateRange_FiltersCorrectly() {
        let day0 = Date(timeIntervalSince1970: 0)
        let day30 = day0.addingTimeInterval(30 * 86400)
        let day60 = day0.addingTimeInterval(60 * 86400)
        let day90 = day0.addingTimeInterval(90 * 86400)

        let transactions: [GoldCalculator.ReplayTransaction] = [
            .init(type: .buy, grams: 100, pricePerGram: 1000, date: day0.addingTimeInterval(86400)),
            .init(type: .sell, grams: 50, pricePerGram: 1200, date: day60.addingTimeInterval(86400)),
        ]

        // Only look at day30...day90: the buy at day1 is before the range
        let metrics = GoldCalculator.computeMetrics(
            allTransactions: transactions,
            dateRange: day30...day90,
            marketPrice: 1100
        )

        // Opening position should be 100g @ 1000 (from before the range)
        XCTAssertEqual(metrics.endPosition.totalGrams, 50, accuracy: epsilon)
        // The sell at day61 IS in range, so it counts
        XCTAssertEqual(metrics.sellCount, 1)
        // The buy at day1 is NOT in range
        XCTAssertEqual(metrics.buyCount, 0)
        XCTAssertEqual(metrics.totalBuyAmount, 0, accuracy: epsilon)
    }

    func testMetrics_WinRate_MultiSell() {
        let start = Date(timeIntervalSince1970: 0)
        let end = start.addingTimeInterval(365 * 86400)

        let transactions: [GoldCalculator.ReplayTransaction] = [
            .init(type: .buy, grams: 100, pricePerGram: 1000, date: start.addingTimeInterval(86400)),
            .init(type: .sell, grams: 20, pricePerGram: 1100, date: start.addingTimeInterval(30 * 86400)),  // win
            .init(type: .sell, grams: 20, pricePerGram: 900, date: start.addingTimeInterval(60 * 86400)),   // loss
            .init(type: .sell, grams: 20, pricePerGram: 1050, date: start.addingTimeInterval(90 * 86400)),  // win
        ]

        let metrics = GoldCalculator.computeMetrics(
            allTransactions: transactions,
            dateRange: start...end,
            marketPrice: 1000
        )

        // 3 sells: 2 wins, 1 loss => win rate = 2/3
        XCTAssertEqual(metrics.winRate!, 2.0 / 3.0, accuracy: epsilon)
        // max win = (1100-1000)*20 = 2000
        XCTAssertEqual(metrics.maxWin, 2000, accuracy: epsilon)
        // max loss = (900-1000)*20 = -2000
        XCTAssertEqual(metrics.maxLoss, -2000, accuracy: epsilon)
    }

    func testMetrics_XIRR_NotNil() {
        let start = Date(timeIntervalSince1970: 0)
        let end = start.addingTimeInterval(365 * 86400)

        let transactions: [GoldCalculator.ReplayTransaction] = [
            .init(type: .buy, grams: 100, pricePerGram: 1000, date: start.addingTimeInterval(86400)),
        ]

        let metrics = GoldCalculator.computeMetrics(
            allTransactions: transactions,
            dateRange: start...end,
            marketPrice: 1100
        )

        // Bought at 1000, worth 1100 after ~1 year => ~10% XIRR
        XCTAssertNotNil(metrics.xirr)
        if let xirr = metrics.xirr {
            XCTAssertEqual(xirr, 0.10, accuracy: 0.02)
        }
    }

    func testMetrics_AnnualizedReturn() {
        let start = Date(timeIntervalSince1970: 0)
        let end = start.addingTimeInterval(180 * 86400) // half year

        let transactions: [GoldCalculator.ReplayTransaction] = [
            .init(type: .buy, grams: 100, pricePerGram: 1000, date: start.addingTimeInterval(86400)),
        ]

        let metrics = GoldCalculator.computeMetrics(
            allTransactions: transactions,
            dateRange: start...end,
            marketPrice: 1050
        )

        // 5% in ~180 days => annualized should be ~10.25%
        XCTAssertNotNil(metrics.annualizedReturn)
        XCTAssertEqual(metrics.simpleReturn, 0.05, accuracy: epsilon)
        if let ann = metrics.annualizedReturn {
            XCTAssertGreaterThan(ann, 0.09)
            XCTAssertLessThan(ann, 0.12)
        }
    }
}
