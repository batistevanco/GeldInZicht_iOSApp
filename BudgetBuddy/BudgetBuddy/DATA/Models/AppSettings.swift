// /Data/Models/AppSettings.swift

import SwiftData
import Foundation

@Model
final class AppSettings {
    var id: UUID = UUID()
    var carryOverBalance: Bool = true
    var carryOverToAccount: Bool = false
    var carryOverAccountID: UUID?
    var preferredPeriodView: PeriodType = PeriodType.month
    var currencyCode: String = "EUR"
    var languageCode: String = "nl"
    var hasOnboardingCompleted: Bool = false
    
    // Recurring transactions

    // Data repair / migration versioning

    init() {
        self.id = UUID()
        self.carryOverBalance = true

        // Nieuw: saldo-doorstort instellingen
        self.carryOverToAccount = false
        self.carryOverAccountID = nil

        self.preferredPeriodView = .month
        self.currencyCode = "EUR"
        self.languageCode = "nl"
        self.hasOnboardingCompleted = false
    }
}
