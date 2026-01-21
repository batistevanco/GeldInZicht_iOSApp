// /Data/Storage/RecurringTransactionEngine.swift

import SwiftData
import Foundation

enum RecurringTransactionEngine {

    static func run(context: ModelContext) {
        // 1. Haal ALLE recurring templates op (zonder predicate-macro)
        let allTransactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
        let templates = allTransactions.filter { $0.isRecurringTemplate }

        guard !templates.isEmpty else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 2. Bestaande gegenereerde transacties (om duplicaten te vermijden)
        let generated = allTransactions.filter { !$0.isRecurringTemplate }

        for template in templates {
            guard template.frequency != .none else { continue }

            // Startpunt = template datum
            var nextDate = calendar.startOfDay(for: template.date)

            // 3. Loop tot vandaag
            while true {
                nextDate = nextOccurrence(after: nextDate, frequency: template.frequency)
                if nextDate > today { break }

                // 4. Check of deze al bestaat (zelfde templateId + datum)
                let alreadyExists = generated.contains {
                    $0.templateId == template.id &&
                    calendar.isDate($0.date, inSameDayAs: nextDate)
                }

                if alreadyExists { continue }

                // 5. Nieuwe transactie aanmaken
                let tx = Transaction(
                    type: template.type,
                    amount: template.amount,
                    date: nextDate,
                    frequency: .none,
                    isRecurringTemplate: false
                )

                // Kopieer relaties
                tx.category = template.category
                tx.sourceAccount = template.sourceAccount
                tx.destinationAccount = template.destinationAccount
                tx.savingGoal = template.savingGoal
                tx.descriptionText = template.descriptionText
                tx.templateId = template.id

                context.insert(tx)
            }
        }

        // 6. Balansen herberekenen
        FinanceEngine.recalculateAll(context: context)

        try? context.save()
    }

    // MARK: - Helper

    private static func nextOccurrence(after date: Date, frequency: TransactionFrequency) -> Date {
        let calendar = Calendar.current

        switch frequency {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date)!
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)!
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date)!
        case .fourMonthly:
            return calendar.date(byAdding: .month, value: 4, to: date)!
        case .sixMonthly:
            return calendar.date(byAdding: .month, value: 6, to: date)!
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date)!
        case .none:
            return date
        }
    }
}
