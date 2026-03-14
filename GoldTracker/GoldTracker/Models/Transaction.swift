import Foundation
import SwiftData

enum TransactionType: String, Codable, CaseIterable {
    case buy = "买入"
    case sell = "卖出"

    var icon: String {
        switch self {
        case .buy: return "arrow.down.circle.fill"
        case .sell: return "arrow.up.circle.fill"
        }
    }
}

@Model
final class Transaction {
    var id: UUID
    var type: TransactionType
    var grams: Double
    var pricePerGram: Double
    var date: Date
    var note: String
    var portfolioName: String

    /// The weighted average cost at the time of this transaction (snapshot)
    var averageCostAtTransaction: Double

    /// Realized profit for sell transactions (calculated at transaction time)
    var realizedProfit: Double

    var totalAmount: Double {
        grams * pricePerGram
    }

    init(
        type: TransactionType,
        grams: Double,
        pricePerGram: Double,
        date: Date = .now,
        note: String = "",
        portfolioName: String = "默认",
        averageCostAtTransaction: Double = 0,
        realizedProfit: Double = 0
    ) {
        self.id = UUID()
        self.type = type
        self.grams = grams
        self.pricePerGram = pricePerGram
        self.date = date
        self.note = note
        self.portfolioName = portfolioName
        self.averageCostAtTransaction = averageCostAtTransaction
        self.realizedProfit = realizedProfit
    }
}
