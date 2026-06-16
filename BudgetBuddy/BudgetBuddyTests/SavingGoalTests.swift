// BudgetBuddyTests/SavingGoalTests.swift

import XCTest
@testable import BudgetBuddy

final class SavingGoalTests: XCTestCase {

    // MARK: - progress

    func test_progress_empty_isZero() {
        let goal = SavingGoal(name: "Test", goalAmount: 1000)
        XCTAssertEqual(goal.progress, 0)
    }

    func test_progress_halfway() {
        let goal = SavingGoal(name: "Test", goalAmount: 1000)
        goal.currentAmount = 500
        XCTAssertEqual(goal.progress, 0.5, accuracy: 0.001)
    }

    func test_progress_full() {
        let goal = SavingGoal(name: "Test", goalAmount: 1000)
        goal.currentAmount = 1000
        XCTAssertEqual(goal.progress, 1.0, accuracy: 0.001)
    }

    func test_progress_over100percent_clipsToOne() {
        let goal = SavingGoal(name: "Test", goalAmount: 1000)
        goal.currentAmount = 1500
        XCTAssertEqual(goal.progress, 1.0)
    }

    func test_progress_negativeAmount_clipsToZero() {
        let goal = SavingGoal(name: "Test", goalAmount: 1000)
        goal.currentAmount = -100
        XCTAssertEqual(goal.progress, 0)
    }

    func test_progress_zeroGoalAmount_isZero() {
        let goal = SavingGoal(name: "Test", goalAmount: 0)
        goal.currentAmount = 500
        XCTAssertEqual(goal.progress, 0)
    }

    func test_progress_25percent() {
        let goal = SavingGoal(name: "Test", goalAmount: 200)
        goal.currentAmount = 50
        XCTAssertEqual(goal.progress, 0.25, accuracy: 0.001)
    }

    func test_progress_almostFull() {
        let goal = SavingGoal(name: "Test", goalAmount: 100)
        goal.currentAmount = 99
        XCTAssertEqual(goal.progress, 0.99, accuracy: 0.001)
    }

    // MARK: - effectiveIcon

    func test_effectiveIcon_withCustomIcon() {
        let goal = SavingGoal(name: "Test", goalAmount: 100)
        goal.iconName = "car.fill"
        XCTAssertEqual(goal.effectiveIcon, "car.fill")
    }

    func test_effectiveIcon_withoutIcon_returnsDefault() {
        let goal = SavingGoal(name: "Test", goalAmount: 100)
        goal.iconName = nil
        XCTAssertEqual(goal.effectiveIcon, "target")
    }

    // MARK: - isArchived default

    func test_isArchived_defaultFalse() {
        let goal = SavingGoal(name: "Test", goalAmount: 100)
        XCTAssertFalse(goal.isArchived)
    }
}
