// BudgetBuddyTests/AccountTests.swift

import XCTest
@testable import BudgetBuddy

final class AccountTests: XCTestCase {

    // MARK: - effectiveIcon

    func test_effectiveIcon_withCustomIcon() {
        let account = Account(name: "Test", type: .checking, initialBalance: 0)
        account.iconName = "star.fill"
        XCTAssertEqual(account.effectiveIcon, "star.fill")
    }

    func test_effectiveIcon_checking_defaultIcon() {
        let account = Account(name: "Test", type: .checking, initialBalance: 0)
        account.iconName = nil
        XCTAssertEqual(account.effectiveIcon, "creditcard.fill")
    }

    func test_effectiveIcon_savings_defaultIcon() {
        let account = Account(name: "Test", type: .savings, initialBalance: 0)
        account.iconName = nil
        XCTAssertEqual(account.effectiveIcon, "banknote.fill")
    }

    func test_effectiveIcon_cash_defaultIcon() {
        let account = Account(name: "Test", type: .cash, initialBalance: 0)
        account.iconName = nil
        XCTAssertEqual(account.effectiveIcon, "banknote")
    }

    func test_effectiveIcon_other_defaultIcon() {
        let account = Account(name: "Test", type: .other, initialBalance: 0)
        account.iconName = nil
        XCTAssertEqual(account.effectiveIcon, "tray.full.fill")
    }

    // MARK: - Defaults

    func test_account_defaultIsDefault_isFalse() {
        let account = Account(name: "Test", type: .checking, initialBalance: 0)
        XCTAssertFalse(account.isDefault)
    }

    func test_account_defaultIsArchived_isFalse() {
        let account = Account(name: "Test", type: .checking, initialBalance: 0)
        XCTAssertFalse(account.isArchived)
    }

    func test_account_initialBalance_storedCorrectly() {
        let account = Account(name: "Test", type: .savings, initialBalance: 2500)
        XCTAssertEqual(account.initialBalance, 2500)
    }

    // MARK: - AppTheme.color helper

    func test_appTheme_color_validHex() {
        let color = AppTheme.color(from: "#4F46E5")
        XCTAssertNotNil(color)
    }

    func test_appTheme_color_invalidHex_returnsNil() {
        let color = AppTheme.color(from: "notacolor")
        XCTAssertNil(color)
    }

    func test_appTheme_color_nilInput_returnsNil() {
        let color = AppTheme.color(from: nil)
        XCTAssertNil(color)
    }

    func test_appTheme_color_withoutHash() {
        let color = AppTheme.color(from: "FF0000")
        XCTAssertNotNil(color)
    }
}
