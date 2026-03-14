import Foundation
import SwiftData

@Model
final class Portfolio {
    var id: UUID
    var name: String
    var totalGrams: Double
    var averageCost: Double
    var totalInvested: Double
    var totalRealizedProfit: Double
    var createdAt: Date

    var totalCostBasis: Double {
        totalGrams * averageCost
    }

    init(
        name: String,
        totalGrams: Double = 0,
        averageCost: Double = 0,
        totalInvested: Double = 0,
        totalRealizedProfit: Double = 0
    ) {
        self.id = UUID()
        self.name = name
        self.totalGrams = totalGrams
        self.averageCost = averageCost
        self.totalInvested = totalInvested
        self.totalRealizedProfit = totalRealizedProfit
        self.createdAt = .now
    }
}
