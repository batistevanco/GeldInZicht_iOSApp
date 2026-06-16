// BudgetBuddyTests/TransactionValidationTests.swift

import XCTest
@testable import BudgetBuddy

final class TransactionValidationTests: XCTestCase {

    private func makeAccount() -> Account {
        Account(name: "Rekening", type: .checking, initialBalance: 0)
    }

    private func makeCategory() -> BudgetBuddy.Category {
        BudgetBuddy.Category(name: "Boodschappen", iconName: "cart")
    }


    private func makeSavingGoal() -> SavingGoal {
        SavingGoal(name: "Vakantie", goalAmount: 1000)
    }

    // MARK: - Bedrag validatie

    func test_validate_zeroAmount_returnsError() {
        let tx = Transaction(type: .income, amount: 0)
        tx.destinationAccount = makeAccount()
        XCTAssertFalse(tx.validate().isEmpty)
    }

    func test_validate_negativeAmount_returnsError() {
        let tx = Transaction(type: .income, amount: -50)
        tx.destinationAccount = makeAccount()
        XCTAssertFalse(tx.validate().isEmpty)
    }

    func test_validate_positiveAmount_noError() {
        let tx = Transaction(type: .income, amount: 100)
        tx.destinationAccount = makeAccount()
        XCTAssertTrue(tx.validate().isEmpty)
    }

    // MARK: - Inkomst validatie

    func test_validate_income_missingDestination_returnsError() {
        let tx = Transaction(type: .income, amount: 100)
        let errors = tx.validate()
        XCTAssertFalse(errors.isEmpty)
        XCTAssertTrue(errors.contains(where: { $0.contains("Bestemmingsrekening") }))
    }

    func test_validate_income_withDestination_noError() {
        let tx = Transaction(type: .income, amount: 100)
        tx.destinationAccount = makeAccount()
        XCTAssertTrue(tx.validate().isEmpty)
    }

    // MARK: - Uitgave validatie

    func test_validate_expense_missingSource_returnsError() {
        let tx = Transaction(type: .expense, amount: 50)
        tx.category = makeCategory()
        let errors = tx.validate()
        XCTAssertTrue(errors.contains(where: { $0.contains("Rekening") }))
    }

    func test_validate_expense_missingCategory_returnsError() {
        let tx = Transaction(type: .expense, amount: 50)
        tx.sourceAccount = makeAccount()
        let errors = tx.validate()
        XCTAssertTrue(errors.contains(where: { $0.contains("Categorie") }))
    }

    func test_validate_expense_missingBoth_returnsTwoErrors() {
        let tx = Transaction(type: .expense, amount: 50)
        let errors = tx.validate()
        XCTAssertGreaterThanOrEqual(errors.count, 2)
    }

    func test_validate_expense_valid_noError() {
        let tx = Transaction(type: .expense, amount: 50)
        tx.sourceAccount = makeAccount()
        tx.category = makeCategory()
        XCTAssertTrue(tx.validate().isEmpty)
    }

    // MARK: - Transfer validatie

    func test_validate_transfer_missingSource_returnsError() {
        let tx = Transaction(type: .transfer, amount: 100)
        tx.destinationAccount = makeAccount()
        let errors = tx.validate()
        XCTAssertFalse(errors.isEmpty)
    }

    func test_validate_transfer_missingDestination_returnsError() {
        let tx = Transaction(type: .transfer, amount: 100)
        tx.sourceAccount = makeAccount()
        let errors = tx.validate()
        XCTAssertFalse(errors.isEmpty)
    }

    func test_validate_transfer_sameSourceAndDestination_returnsError() {
        let account = makeAccount()
        let tx = Transaction(type: .transfer, amount: 100)
        tx.sourceAccount = account
        tx.destinationAccount = account
        let errors = tx.validate()
        XCTAssertTrue(errors.contains(where: { $0.contains("dezelfde") }))
    }

    func test_validate_transfer_valid_noError() {
        let tx = Transaction(type: .transfer, amount: 100)
        tx.sourceAccount = makeAccount()
        tx.destinationAccount = makeAccount()
        XCTAssertTrue(tx.validate().isEmpty)
    }

    // MARK: - Spaardepot validatie

    func test_validate_savingDeposit_missingSource_returnsError() {
        let tx = Transaction(type: .savingDeposit, amount: 100)
        tx.savingGoal = makeSavingGoal()
        let errors = tx.validate()
        XCTAssertTrue(errors.contains(where: { $0.contains("Bronrekening") }))
    }

    func test_validate_savingDeposit_missingGoal_returnsError() {
        let tx = Transaction(type: .savingDeposit, amount: 100)
        tx.sourceAccount = makeAccount()
        let errors = tx.validate()
        XCTAssertTrue(errors.contains(where: { $0.contains("Spaarpot") }))
    }

    func test_validate_savingDeposit_valid_noError() {
        let tx = Transaction(type: .savingDeposit, amount: 100)
        tx.sourceAccount = makeAccount()
        tx.savingGoal = makeSavingGoal()
        XCTAssertTrue(tx.validate().isEmpty)
    }

    // MARK: - Spaartrekking validatie

    func test_validate_savingWithdrawal_missingDestination_returnsError() {
        let tx = Transaction(type: .savingWithdrawal, amount: 100)
        tx.savingGoal = makeSavingGoal()
        let errors = tx.validate()
        XCTAssertTrue(errors.contains(where: { $0.contains("Bestemmingsrekening") }))
    }

    func test_validate_savingWithdrawal_missingGoal_returnsError() {
        let tx = Transaction(type: .savingWithdrawal, amount: 100)
        tx.destinationAccount = makeAccount()
        let errors = tx.validate()
        XCTAssertTrue(errors.contains(where: { $0.contains("Spaarpot") }))
    }

    func test_validate_savingWithdrawal_valid_noError() {
        let tx = Transaction(type: .savingWithdrawal, amount: 100)
        tx.destinationAccount = makeAccount()
        tx.savingGoal = makeSavingGoal()
        XCTAssertTrue(tx.validate().isEmpty)
    }
}
