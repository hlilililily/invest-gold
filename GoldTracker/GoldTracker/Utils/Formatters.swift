import Foundation

enum Formatters {
    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "zh_CN")
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f
    }()

    static let decimal: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 4
        f.minimumFractionDigits = 0
        return f
    }()

    static let grams: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        f.positiveSuffix = "g"
        return f
    }()

    static let dateShort: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    static func priceString(_ value: Double) -> String {
        currency.string(from: NSNumber(value: value)) ?? "¥0.00"
    }

    static func gramsString(_ value: Double) -> String {
        grams.string(from: NSNumber(value: value)) ?? "0g"
    }

    static func profitString(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return sign + priceString(value)
    }

    static func percentString(_ value: Double) -> String {
        String(format: "%+.2f%%", value * 100)
    }
}
