// /Data/Models/AppSettings.swift

import SwiftData
import Foundation

@Model
final class AppSettings {
    var id: UUID
    var carryOverBalance: Bool
    var carryOverToAccount: Bool
    var carryOverAccountID: UUID?
    var preferredPeriodView: PeriodType
    var currencyCode: String
    var languageCode: String
    var hasOnboardingCompleted: Bool

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
