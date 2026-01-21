// /Data/Storage/FinanceEngine.swift

import Foundation
import SwiftData

enum FinanceEngine {

    // MARK: - Totals (gebruikt in BudgetOverview)

    static func totals(
        for transactions: [Transaction],
        period: PeriodType,
        referenceDate: Date
    ) -> (income: Decimal, expense: Decimal) {

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
        let yearTransactions = transactions.filter {
            calendar.component(.year, from: $0.date) == year
        }

        var buckets: [String: (income: Decimal, expense: Decimal)] = [:]

        for tx in yearTransactions {
            let key: String

            switch period {
            case .month:
                key = tx.date.formatted(.dateTime.month(.wide))
            case .week:
                let week = calendar.component(.weekOfYear, from: tx.date)
                key = "Week \(week)"
            case .year:
                key = String(year)
            }

            var current = buckets[key] ?? (0, 0)

            if tx.type == .income {
                current.income += tx.amount
            } else if tx.type == .expense {
                current.expense += tx.amount
            }

            buckets[key] = current
        }

        return buckets.map { key, value in
            PeriodSummary(
                id: UUID(),
                label: key,
                income: value.income,
                expense: value.expense
            )
        }
        .sorted { $0.label < $1.label }
    }

    // MARK: - Net worth

    static func netWorth(
        accounts: [Account],
        transactions: [Transaction]
    ) -> Decimal {

        accounts
            .filter { !$0.isArchived }
            .reduce(0) { result, account in
                result + accountBalance(account, transactions: transactions)
            }
    }

    static func accountBalance(
        _ account: Account,
        transactions: [Transaction]
    ) -> Decimal {

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

        // 2. Vorige maand bepalen
        guard
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: referenceDate),
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: previousMonth)),
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)
        else { return }

        // 3. Check of carry-over al gebeurd is (duplicate preventie)
        let allTransactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []

        let existing = allTransactions.first {
            $0.type == .income &&
            $0.descriptionText == "Saldo overgedragen vorige maand" &&
            $0.date >= monthStart &&
            $0.date <= monthEnd
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
            date: calendar.date(byAdding: .day, value: 1, to: monthEnd) ?? referenceDate
        )

        carryTx.destinationAccount = targetAccount
        carryTx.descriptionText = "Saldo overgedragen vorige maand"
        carryTx.frequency = .none
        carryTx.isRecurringTemplate = false

        context.insert(carryTx)
        try? context.save()
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
    let income: Decimal
    let expense: Decimal

    var net: Decimal {
        income - expense
    }
}
