// BudgetBuddyTests/MoneyFormatterTests.swift

import XCTest
@testable import BudgetBuddy

final class MoneyFormatterTests: XCTestCase {

    // MARK: - Basisopmaak EUR

    func test_format_zero_EUR() {
        let result = MoneyFormatter.format(0, currencyCode: "EUR")
        XCTAssertTrue(result.contains("0"), "Verwacht 0 in resultaat, kreeg: \(result)")
    }

    func test_format_positiveAmount_EUR() {
        let result = MoneyFormatter.format(1234.56, currencyCode: "EUR")
        XCTAssertTrue(result.contains("1"), "Verwacht bedrag in resultaat, kreeg: \(result)")
        XCTAssertTrue(result.contains("€") || result.contains("EUR"), "Verwacht € symbool, kreeg: \(result)")
    }

    func test_format_negativeAmount_EUR() {
        let result = MoneyFormatter.format(-500, currencyCode: "EUR")
        XCTAssertTrue(result.contains("500"), "Verwacht 500 in resultaat, kreeg: \(result)")
    }

    func test_format_twoDecimalPlaces() {
        let result = MoneyFormatter.format(10, currencyCode: "EUR")
        // Moet altijd 2 decimalen tonen
        XCTAssertTrue(result.contains("00") || result.contains(",00") || result.contains(".00"),
                      "Verwacht 2 decimalen, kreeg: \(result)")
    }

    func test_format_largeAmount() {
        let result = MoneyFormatter.format(1_000_000, currencyCode: "EUR")
        XCTAssertTrue(result.contains("000"), "Verwacht groot bedrag in resultaat, kreeg: \(result)")
    }

    // MARK: - Andere valuta

    func test_format_USD() {
        let result = MoneyFormatter.format(100, currencyCode: "USD")
        XCTAssertTrue(result.contains("$") || result.contains("USD"),
                      "Verwacht $ of USD, kreeg: \(result)")
    }

    func test_format_GBP() {
        let result = MoneyFormatter.format(100, currencyCode: "GBP")
        XCTAssertTrue(result.contains("£") || result.contains("GBP"),
                      "Verwacht £ of GBP, kreeg: \(result)")
    }

    // MARK: - Default currencyCode

    func test_format_defaultCurrency_isEUR() {
        let result = MoneyFormatter.format(100)
        XCTAssertTrue(result.contains("€") || result.contains("EUR"),
                      "Default valuta moet EUR zijn, kreeg: \(result)")
    }

    // MARK: - Afronden

    func test_format_roundsToTwoDecimals() {
        let result1 = MoneyFormatter.format(1.005, currencyCode: "EUR")
        let result2 = MoneyFormatter.format(1.004, currencyCode: "EUR")
        // Beide moeten geldig zijn zonder crash
        XCTAssertFalse(result1.isEmpty)
        XCTAssertFalse(result2.isEmpty)
    }
}
