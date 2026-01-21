// /Data/Models/Transaction.swift

import SwiftData
import Foundation

@Model
final class Transaction {
    var id: UUID
    var templateId: UUID?            // used for recurring generated items
    var type: TransactionType
    var amount: Decimal
    var descriptionText: String?
    var date: Date
    var frequency: TransactionFrequency
    var isRecurringTemplate: Bool

    var category: Category?
    var sourceAccount: Account?
    var destinationAccount: Account?
    var savingGoal: SavingGoal?

    var createdAt: Date
    var updatedAt: Date

    init(
        type: TransactionType,
        amount: Decimal,
        date: Date = .now,
        frequency: TransactionFrequency = .none,
        isRecurringTemplate: Bool = false
    ) {
        self.id = UUID()
        self.type = type
        self.amount = amount
        self.date = date
        self.frequency = frequency
        self.isRecurringTemplate = isRecurringTemplate
        self.createdAt = .now
        self.updatedAt = .now
    }

    func validate() -> [String] {
        var errors: [String] = []
        if amount <= 0 { errors.append("Bedrag moet groter zijn dan 0.") }

        switch type {
        case .income:
            // ✅ Geen rekening vereist voor inkomsten
            // (Categorie wordt gekozen in de UI; indien je later ook categorie-validatie voor income wil,
            // voeg dat hier toe. Voor nu: geen rekening-check.)
            break

        case .expense:
            if sourceAccount == nil { errors.append("Rekening is verplicht voor uitgaven.") }
            if category == nil { errors.append("Categorie is verplicht voor uitgaven.") }

        case .transfer:
            if sourceAccount == nil || destinationAccount == nil { errors.append("Bron en bestemming zijn verplicht.") }
            if let s = sourceAccount, let d = destinationAccount, s.id == d.id {
                errors.append("Bron en bestemming mogen niet dezelfde rekening zijn.")
            }

        case .savingDeposit:
            if sourceAccount == nil { errors.append("Bronrekening is verplicht.") }
            if savingGoal == nil { errors.append("Spaarpot is verplicht.") }

        case .savingWithdrawal:
            if destinationAccount == nil { errors.append("Bestemmingsrekening is verplicht.") }
            if savingGoal == nil { errors.append("Spaarpot is verplicht.") }
        }

        return errors
    }
}
