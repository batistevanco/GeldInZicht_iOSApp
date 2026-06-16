// /Data/Storage/FinanceEngine.swift

import Foundation
import SwiftData

enum FinanceEngine {

    // MARK: - Totals (gebruikt in BudgetOverview)

    static func totals(
        for transactions: [Transaction],
        period: PeriodType,
        referenceDate: Date
    ) -> (income: Double, expense: Double) {

        let filtered = filteredTransactions(
            transactions,
            period: period,
            referenceDate: referenceDate
        )

        let income = filtered
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }

        let expense = filtered
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }

        return (income, expense)
    }

    // MARK: - Filtering per period

    static func filteredTransactions(
        _ transactions: [Transaction],
        period: PeriodType,
        referenceDate: Date
    ) -> [Transaction] {

        let calendar = Calendar.current

        return transactions.filter { tx in
            switch period {
            case .week:
                return calendar.isDate(tx.date, equalTo: referenceDate, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(tx.date, equalTo: referenceDate, toGranularity: .month)
            case .year:
                return calendar.isDate(tx.date, equalTo: referenceDate, toGranularity: .year)
            }
        }
        .sorted { $0.date > $1.date }
    }

    // MARK: - Period summaries (❗ DE MISSENDE FUNCTIE)

    static func periodSummaries(
        transactions: [Transaction],
        period: PeriodType,
        year: Int
    ) -> [PeriodSummary] {

        let calendar = Calendar.current

        // Keep only transactions that fall inside the requested calendar year
        let yearTransactions = transactions.filter {
            calendar.component(.year, from: $0.date) == year
        }

        // Use sortable keys (Int/Double) instead of localized strings to avoid alphabetical sorting.
        // Then derive the human-readable label from the key.
        struct Bucket {
            var label: String
            var income: Double
            var expense: Double
        }

        var buckets: [Int: Bucket] = [:]

        for tx in yearTransactions {
            let key: Int
            let label: String

            switch period {
            case .month:
                let month = calendar.component(.month, from: tx.date) // 1...12
                key = month
                // Month name in current locale (year is already implied by the selected year)
                label = tx.date.formatted(.dateTime.month(.wide))

            case .week:
                let week = calendar.component(.weekOfYear, from: tx.date)
                key = week
                label = "Week \(week)"

            case .year:
                key = year
                label = String(year)
            }

            var current = buckets[key] ?? Bucket(label: label, income: 0, expense: 0)

            if tx.type == .income {
                current.income += tx.amount
            } else if tx.type == .expense {
                current.expense += tx.amount
            }

            buckets[key] = current
        }

        return buckets
            .sorted { $0.key < $1.key }
            .map { _, value in
                PeriodSummary(
                    id: UUID(),
                    label: value.label,
                    income: value.income,
                    expense: value.expense
                )
            }
    }

    // MARK: - Net worth

    static func netWorth(
        accounts: [Account],
        transactions: [Transaction]
    ) -> Double {

        accounts
            .filter { !$0.isArchived }
            .reduce(0) { result, account in
                result + accountBalance(account, transactions: transactions)
            }
    }

    static func accountBalance(
        _ account: Account,
        transactions: [Transaction]
    ) -> Double {

        var balance = account.initialBalance

        for tx in transactions {
            switch tx.type {
            case .income:
                if tx.destinationAccount?.id == account.id {
                    balance += tx.amount
                }

            case .expense:
                if tx.sourceAccount?.id == account.id {
                    balance -= tx.amount
                }

            case .transfer:
                if tx.sourceAccount?.id == account.id {
                    balance -= tx.amount
                }
                if tx.destinationAccount?.id == account.id {
                    balance += tx.amount
                }

            case .savingDeposit:
                if tx.sourceAccount?.id == account.id {
                    balance -= tx.amount
                }

            case .savingWithdrawal:
                if tx.destinationAccount?.id == account.id {
                    balance += tx.amount
                }
            }
        }

        return balance
    }

    // MARK: - Monthly carry-over

    static func applyMonthlyCarryOverIfNeeded(
        context: ModelContext,
        referenceDate: Date = Date()
    ) {
        let calendar = Calendar.current

        // 1. Settings ophalen
        guard
            let settings = try? context.fetch(FetchDescriptor<AppSettings>()).first,
            settings.carryOverBalance,
            settings.carryOverToAccount,
            let targetAccountID = settings.carryOverAccountID
        else { return }

        // 2. Bepaal vorige maand (start & einde) en start van de huidige maand
        guard
            let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate)),
            let previousMonthStart = calendar.date(byAdding: .month, value: -1, to: currentMonthStart),
            let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: previousMonthStart),
            let previousMonthEnd = calendar.date(byAdding: .second, value: -1, to: nextMonthStart)
        else { return }

        let monthStart = previousMonthStart
        let monthEnd = previousMonthEnd

        // We create the carry-over as an income on the first day of the current month.
        let carryOverDate = currentMonthStart

        // 3. Check of carry-over al gebeurd is (duplicate preventie)
        // NOTE: the carry-over transaction is created on `carryOverDate` (start of current month),
        // so we must look for it in the current month, not in the previous month.
        let allTransactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []

        let existing = allTransactions.first {
            $0.type == .income &&
            $0.descriptionText == "Saldo overgedragen vorige maand" &&
            calendar.isDate($0.date, inSameDayAs: carryOverDate) &&
            $0.destinationAccount?.id == targetAccountID
        }

        if existing != nil { return }

        // 4. Nodige data ophalen
        let accounts = (try? context.fetch(FetchDescriptor<Account>())) ?? []
        let transactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []

        guard let targetAccount = accounts.first(where: { $0.id == targetAccountID }) else { return }

        // 5. Eindsaldo vorige maand berekenen
        let monthTransactions = transactions.filter {
            $0.date >= monthStart && $0.date <= monthEnd
        }

        let income = monthTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }

        let expense = monthTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }

        let carryOverAmount = income - expense
        guard carryOverAmount > 0 else { return }

        // 6. Income-transactie aanmaken
        let carryTx = Transaction(
            type: .income,
            amount: carryOverAmount,
            date: carryOverDate
        )

        carryTx.destinationAccount = targetAccount
        carryTx.descriptionText = "Saldo overgedragen vorige maand"
        carryTx.frequency = .none
        carryTx.isRecurringTemplate = false

        context.insert(carryTx)
        try? context.save()
    }

    // MARK: - Insights

    /// Recurring templates that will still fire between `referenceDate` and end of month,
    /// and have NOT yet been generated for that date.
    static func pendingRecurringThisMonth(
        allTransactions: [Transaction],
        referenceDate: Date = Date()
    ) -> [Transaction] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: referenceDate)

        guard
            let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: referenceDate)),
            let nextMonthStart = cal.date(byAdding: .month, value: 1, to: monthStart),
            let monthEnd = cal.date(byAdding: .second, value: -1, to: nextMonthStart)
        else { return [] }

        let templates = allTransactions.filter { $0.isRecurringTemplate && $0.frequency != .none }
        let generated = allTransactions.filter { !$0.isRecurringTemplate }

        var pending: [Transaction] = []

        for template in templates {
            var cursor = cal.startOfDay(for: template.date)

            // Advance cursor to first occurrence after today that falls within this month
            while true {
                guard let next = nextRecurringOccurrence(after: cursor, frequency: template.frequency) else { break }
                cursor = next

                if cursor > monthEnd { break }
                if cursor <= today { continue }

                // In this month and in the future — check if already generated
                let exists = generated.contains {
                    $0.templateId == template.id &&
                    cal.isDate($0.date, inSameDayAs: cursor)
                }

                if !exists {
                    pending.append(template)
                }

                // Only need first future occurrence per template this month
                break
            }
        }

        return pending
    }

    /// Projected end-of-month balance = current net + pending recurring income - pending recurring expenses
    static func expectedEndBalance(
        currentNet: Double,
        allTransactions: [Transaction],
        referenceDate: Date = Date()
    ) -> Double {
        let pending = pendingRecurringThisMonth(allTransactions: allTransactions, referenceDate: referenceDate)
        let pendingIncome = pending.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let pendingExpenses = pending.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        return currentNet + pendingIncome - pendingExpenses
    }

    /// Net worth growth vs start of current month
    static func netWorthGrowth(
        accounts: [Account],
        allTransactions: [Transaction],
        referenceDate: Date = Date()
    ) -> Double {
        let cal = Calendar.current
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: referenceDate)) else { return 0 }

        let currentNW = netWorth(accounts: accounts, transactions: allTransactions)

        // Net worth at start of month = current - transactions that happened this month
        let monthTx = allTransactions.filter { $0.date >= monthStart }
        let monthIncome = monthTx.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let monthExpenses = monthTx.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let startOfMonthNW = currentNW - monthIncome + monthExpenses

        return currentNW - startOfMonthNW
    }

    private static func nextRecurringOccurrence(after date: Date, frequency: TransactionFrequency) -> Date? {
        let cal = Calendar.current
        switch frequency {
        case .weekly:      return cal.date(byAdding: .weekOfYear, value: 1, to: date)
        case .monthly:     return cal.date(byAdding: .month, value: 1, to: date)
        case .quarterly:   return cal.date(byAdding: .month, value: 3, to: date)
        case .fourMonthly: return cal.date(byAdding: .month, value: 4, to: date)
        case .sixMonthly:  return cal.date(byAdding: .month, value: 6, to: date)
        case .yearly:      return cal.date(byAdding: .year, value: 1, to: date)
        case .none:        return nil
        }
    }

    // MARK: - Recalculate all

    static func recalculateAll(context: ModelContext) {
        _ = (try? context.fetch(FetchDescriptor<Account>())) ?? []
        let goals = (try? context.fetch(FetchDescriptor<SavingGoal>())) ?? []
        let transactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []

        for goal in goals {
            goal.currentAmount = transactions.reduce(0) { sum, tx in
                if tx.savingGoal?.id == goal.id {
                    if tx.type == .savingDeposit { return sum + tx.amount }
                    if tx.type == .savingWithdrawal { return sum - tx.amount }
                }
                return sum
            }
        }

        try? context.save()
    }
}

// MARK: - PeriodSummary model

struct PeriodSummary: Identifiable {
    let id: UUID
    let label: String
    let income: Double
    let expense: Double

    var net: Double {
        income - expense
    }
}
