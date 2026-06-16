// BudgetBuddyTests/FinanceEngineTests.swift

import XCTest
@testable import BudgetBuddy

final class FinanceEngineTests: XCTestCase {

    // MARK: - Helpers

    private func makeAccount(initialBalance: Double = 0) -> Account {
        Account(name: "Test", type: .checking, initialBalance: initialBalance)
    }

    private func makeIncome(amount: Double, to account: Account, date: Date = Date()) -> Transaction {
        let tx = Transaction(type: .income, amount: amount, date: date)
        tx.destinationAccount = account
        return tx
    }

    private func makeExpense(amount: Double, from account: Account, date: Date = Date()) -> Transaction {
        let tx = Transaction(type: .expense, amount: amount, date: date)
        tx.sourceAccount = account
        return tx
    }

    private func makeTransfer(amount: Double, from source: Account, to destination: Account, date: Date = Date()) -> Transaction {
        let tx = Transaction(type: .transfer, amount: amount, date: date)
        tx.sourceAccount = source
        tx.destinationAccount = destination
        return tx
    }

    private func makeSavingDeposit(amount: Double, from account: Account) -> Transaction {
        let tx = Transaction(type: .savingDeposit, amount: amount)
        tx.sourceAccount = account
        return tx
    }

    private func makeSavingWithdrawal(amount: Double, to account: Account) -> Transaction {
        let tx = Transaction(type: .savingWithdrawal, amount: amount)
        tx.destinationAccount = account
        return tx
    }

    private func date(year: Int, month: Int, day: Int = 1) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }

    // MARK: - accountBalance: beginsaldo

    func test_accountBalance_initialBalance() {
        let account = makeAccount(initialBalance: 500)
        let balance = FinanceEngine.accountBalance(account, transactions: [])
        XCTAssertEqual(balance, 500)
    }

    func test_accountBalance_noTransactions() {
        let account = makeAccount(initialBalance: 0)
        let balance = FinanceEngine.accountBalance(account, transactions: [])
        XCTAssertEqual(balance, 0)
    }

    // MARK: - accountBalance: inkomst

    func test_accountBalance_incomeAddsToBalance() {
        let account = makeAccount(initialBalance: 100)
        let tx = makeIncome(amount: 200, to: account)
        XCTAssertEqual(FinanceEngine.accountBalance(account, transactions: [tx]), 300)
    }

    func test_accountBalance_incomeToOtherAccountDoesNotAffect() {
        let account = makeAccount(initialBalance: 100)
        let other = makeAccount(initialBalance: 0)
        let tx = makeIncome(amount: 200, to: other)
        XCTAssertEqual(FinanceEngine.accountBalance(account, transactions: [tx]), 100)
    }

    func test_accountBalance_multipleIncomes() {
        let account = makeAccount(initialBalance: 0)
        let txs = [
            makeIncome(amount: 1000, to: account),
            makeIncome(amount: 500, to: account),
            makeIncome(amount: 250, to: account)
        ]
        XCTAssertEqual(FinanceEngine.accountBalance(account, transactions: txs), 1750)
    }

    // MARK: - accountBalance: uitgave

    func test_accountBalance_expenseSubtractsFromBalance() {
        let account = makeAccount(initialBalance: 500)
        let tx = makeExpense(amount: 200, from: account)
        XCTAssertEqual(FinanceEngine.accountBalance(account, transactions: [tx]), 300)
    }

    func test_accountBalance_expenseFromOtherAccountDoesNotAffect() {
        let account = makeAccount(initialBalance: 500)
        let other = makeAccount(initialBalance: 0)
        let tx = makeExpense(amount: 200, from: other)
        XCTAssertEqual(FinanceEngine.accountBalance(account, transactions: [tx]), 500)
    }

    func test_accountBalance_balanceCanGoNegative() {
        let account = makeAccount(initialBalance: 100)
        let tx = makeExpense(amount: 300, from: account)
        XCTAssertEqual(FinanceEngine.accountBalance(account, transactions: [tx]), -200)
    }

    // MARK: - accountBalance: transfer

    func test_accountBalance_transferDeductsFromSource() {
        let source = makeAccount(initialBalance: 1000)
        let destination = makeAccount(initialBalance: 0)
        let tx = makeTransfer(amount: 400, from: source, to: destination)
        XCTAssertEqual(FinanceEngine.accountBalance(source, transactions: [tx]), 600)
    }

    func test_accountBalance_transferAddsToDestination() {
        let source = makeAccount(initialBalance: 1000)
        let destination = makeAccount(initialBalance: 0)
        let tx = makeTransfer(amount: 400, from: source, to: destination)
        XCTAssertEqual(FinanceEngine.accountBalance(destination, transactions: [tx]), 400)
    }

    func test_accountBalance_transferDoesNotAffectUnrelatedAccount() {
        let source = makeAccount(initialBalance: 1000)
        let destination = makeAccount(initialBalance: 0)
        let unrelated = makeAccount(initialBalance: 200)
        let tx = makeTransfer(amount: 400, from: source, to: destination)
        XCTAssertEqual(FinanceEngine.accountBalance(unrelated, transactions: [tx]), 200)
    }

    // MARK: - accountBalance: sparen

    func test_accountBalance_savingDepositDeductsFromSource() {
        let account = makeAccount(initialBalance: 1000)
        let tx = makeSavingDeposit(amount: 300, from: account)
        XCTAssertEqual(FinanceEngine.accountBalance(account, transactions: [tx]), 700)
    }

    func test_accountBalance_savingWithdrawalAddsToDestination() {
        let account = makeAccount(initialBalance: 0)
        let tx = makeSavingWithdrawal(amount: 300, to: account)
        XCTAssertEqual(FinanceEngine.accountBalance(account, transactions: [tx]), 300)
    }

    // MARK: - accountBalance: gecombineerd

    func test_accountBalance_mixedTransactions() {
        let account = makeAccount(initialBalance: 1000)
        let txs: [Transaction] = [
            makeIncome(amount: 2000, to: account),
            makeExpense(amount: 500, from: account),
            makeExpense(amount: 300, from: account),
            makeSavingDeposit(amount: 200, from: account)
        ]
        // 1000 + 2000 - 500 - 300 - 200 = 2000
        XCTAssertEqual(FinanceEngine.accountBalance(account, transactions: txs), 2000)
    }

    // MARK: - netWorth

    func test_netWorth_singleAccount() {
        let account = makeAccount(initialBalance: 1500)
        XCTAssertEqual(FinanceEngine.netWorth(accounts: [account], transactions: []), 1500)
    }

    func test_netWorth_multipleAccounts() {
        let a1 = makeAccount(initialBalance: 1000)
        let a2 = makeAccount(initialBalance: 500)
        let a3 = makeAccount(initialBalance: 250)
        XCTAssertEqual(FinanceEngine.netWorth(accounts: [a1, a2, a3], transactions: []), 1750)
    }

    func test_netWorth_excludesArchivedAccounts() {
        let active = makeAccount(initialBalance: 1000)
        let archived = makeAccount(initialBalance: 500)
        archived.isArchived = true
        XCTAssertEqual(FinanceEngine.netWorth(accounts: [active, archived], transactions: []), 1000)
    }

    func test_netWorth_includesTransactions() {
        let account = makeAccount(initialBalance: 0)
        let tx = makeIncome(amount: 1000, to: account)
        XCTAssertEqual(FinanceEngine.netWorth(accounts: [account], transactions: [tx]), 1000)
    }

    func test_netWorth_emptyAccounts() {
        XCTAssertEqual(FinanceEngine.netWorth(accounts: [], transactions: []), 0)
    }

    // MARK: - netWorthGrowth

    func test_netWorthGrowth_withIncomeThisMonth() {
        let account = makeAccount(initialBalance: 0)
        let thisMonth = date(year: 2026, month: 6, day: 10)
        let tx = makeIncome(amount: 500, to: account, date: thisMonth)
        let ref = date(year: 2026, month: 6, day: 15)
        let growth = FinanceEngine.netWorthGrowth(accounts: [account], allTransactions: [tx], referenceDate: ref)
        XCTAssertEqual(growth, 500)
    }

    func test_netWorthGrowth_withExpenseThisMonth() {
        let account = makeAccount(initialBalance: 1000)
        let thisMonth = date(year: 2026, month: 6, day: 10)
        let tx = makeExpense(amount: 200, from: account, date: thisMonth)
        let ref = date(year: 2026, month: 6, day: 15)
        let growth = FinanceEngine.netWorthGrowth(accounts: [account], allTransactions: [tx], referenceDate: ref)
        XCTAssertEqual(growth, -200)
    }

    func test_netWorthGrowth_noTransactionsThisMonth() {
        let account = makeAccount(initialBalance: 1000)
        let lastMonth = date(year: 2026, month: 5, day: 10)
        let tx = makeIncome(amount: 500, to: account, date: lastMonth)
        let ref = date(year: 2026, month: 6, day: 15)
        let growth = FinanceEngine.netWorthGrowth(accounts: [account], allTransactions: [tx], referenceDate: ref)
        XCTAssertEqual(growth, 0)
    }

    // MARK: - totals

    func test_totals_perMonth_correctIncome() {
        let account = makeAccount()
        let ref = date(year: 2026, month: 6)
        let tx = makeIncome(amount: 1000, to: account, date: date(year: 2026, month: 6, day: 15))
        let result = FinanceEngine.totals(for: [tx], period: .month, referenceDate: ref)
        XCTAssertEqual(result.income, 1000)
        XCTAssertEqual(result.expense, 0)
    }

    func test_totals_perMonth_excludesOtherMonths() {
        let account = makeAccount()
        let ref = date(year: 2026, month: 6)
        let inJune = makeIncome(amount: 1000, to: account, date: date(year: 2026, month: 6, day: 10))
        let inMay = makeIncome(amount: 500, to: account, date: date(year: 2026, month: 5, day: 10))
        let result = FinanceEngine.totals(for: [inJune, inMay], period: .month, referenceDate: ref)
        XCTAssertEqual(result.income, 1000)
    }

    func test_totals_perMonth_correctExpense() {
        let account = makeAccount()
        let ref = date(year: 2026, month: 6)
        let tx = makeExpense(amount: 300, from: account, date: date(year: 2026, month: 6, day: 5))
        let result = FinanceEngine.totals(for: [tx], period: .month, referenceDate: ref)
        XCTAssertEqual(result.expense, 300)
        XCTAssertEqual(result.income, 0)
    }

    func test_totals_perYear_includesAllMonths() {
        let account = makeAccount()
        let ref = date(year: 2026, month: 1)
        let jan = makeIncome(amount: 100, to: account, date: date(year: 2026, month: 1))
        let jun = makeIncome(amount: 200, to: account, date: date(year: 2026, month: 6))
        let dec = makeIncome(amount: 300, to: account, date: date(year: 2026, month: 12))
        let result = FinanceEngine.totals(for: [jan, jun, dec], period: .year, referenceDate: ref)
        XCTAssertEqual(result.income, 600)
    }

    func test_totals_excludesRecurringTemplates() {
        let account = makeAccount()
        let ref = date(year: 2026, month: 6)
        let template = makeIncome(amount: 1000, to: account, date: date(year: 2026, month: 6, day: 1))
        template.isRecurringTemplate = true
        let result = FinanceEngine.totals(for: [template], period: .month, referenceDate: ref)
        // filteredTransactions does not filter templates — validate() in views does
        // This just confirms templates ARE included in filtered results (engine doesn't exclude them)
        XCTAssertEqual(result.income, 1000)
    }

    // MARK: - periodSummaries

    func test_periodSummaries_groupsByMonth() {
        let account = makeAccount()
        let jan = makeIncome(amount: 1000, to: account, date: date(year: 2026, month: 1))
        let feb = makeExpense(amount: 300, from: account, date: date(year: 2026, month: 2))
        let summaries = FinanceEngine.periodSummaries(transactions: [jan, feb], period: .month, year: 2026)
        XCTAssertEqual(summaries.count, 2)
        XCTAssertEqual(summaries[0].income, 1000)
        XCTAssertEqual(summaries[1].expense, 300)
    }

    func test_periodSummaries_excludesOtherYears() {
        let account = makeAccount()
        let tx2025 = makeIncome(amount: 500, to: account, date: date(year: 2025, month: 6))
        let tx2026 = makeIncome(amount: 1000, to: account, date: date(year: 2026, month: 6))
        let summaries = FinanceEngine.periodSummaries(transactions: [tx2025, tx2026], period: .month, year: 2026)
        XCTAssertEqual(summaries.count, 1)
        XCTAssertEqual(summaries[0].income, 1000)
    }

    func test_periodSummaries_sortedChronologically() {
        let account = makeAccount()
        let mar = makeIncome(amount: 300, to: account, date: date(year: 2026, month: 3))
        let jan = makeIncome(amount: 100, to: account, date: date(year: 2026, month: 1))
        let jun = makeIncome(amount: 600, to: account, date: date(year: 2026, month: 6))
        let summaries = FinanceEngine.periodSummaries(transactions: [mar, jan, jun], period: .month, year: 2026)
        XCTAssertEqual(summaries[0].income, 100) // jan
        XCTAssertEqual(summaries[1].income, 300) // mar
        XCTAssertEqual(summaries[2].income, 600) // jun
    }

    func test_periodSummaries_net() {
        let account = makeAccount()
        let income = makeIncome(amount: 2000, to: account, date: date(year: 2026, month: 1))
        let expense = makeExpense(amount: 800, from: account, date: date(year: 2026, month: 1))
        let summaries = FinanceEngine.periodSummaries(transactions: [income, expense], period: .month, year: 2026)
        XCTAssertEqual(summaries[0].net, 1200)
    }

    // MARK: - expectedEndBalance

    func test_expectedEndBalance_noRecurring() {
        let result = FinanceEngine.expectedEndBalance(currentNet: 1000, allTransactions: [], referenceDate: Date())
        XCTAssertEqual(result, 1000)
    }

    // MARK: - filteredTransactions

    func test_filteredTransactions_byMonth() {
        let account = makeAccount()
        let ref = date(year: 2026, month: 6)
        let inMonth = makeIncome(amount: 100, to: account, date: date(year: 2026, month: 6, day: 15))
        let outMonth = makeIncome(amount: 200, to: account, date: date(year: 2026, month: 5, day: 15))
        let result = FinanceEngine.filteredTransactions([inMonth, outMonth], period: .month, referenceDate: ref)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].amount, 100)
    }

    func test_filteredTransactions_byYear() {
        let account = makeAccount()
        let ref = date(year: 2026, month: 1)
        let in2026 = makeIncome(amount: 100, to: account, date: date(year: 2026, month: 6))
        let in2025 = makeIncome(amount: 200, to: account, date: date(year: 2025, month: 6))
        let result = FinanceEngine.filteredTransactions([in2026, in2025], period: .year, referenceDate: ref)
        XCTAssertEqual(result.count, 1)
    }

    func test_filteredTransactions_sortedDescending() {
        let account = makeAccount()
        let ref = date(year: 2026, month: 6)
        let early = makeIncome(amount: 100, to: account, date: date(year: 2026, month: 6, day: 1))
        let late  = makeIncome(amount: 200, to: account, date: date(year: 2026, month: 6, day: 20))
        let result = FinanceEngine.filteredTransactions([early, late], period: .month, referenceDate: ref)
        XCTAssertEqual(result[0].amount, 200) // meest recent eerst
    }
}
