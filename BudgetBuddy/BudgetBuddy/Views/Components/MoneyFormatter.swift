// /Views/Components/MoneyFormatter.swift

import Foundation

enum MoneyFormatter {

    /// Default currency = EUR (zodat bestaande calls zonder currencyCode blijven compileren)
    static func format(_ value: Double, currencyCode: String = "EUR") -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
