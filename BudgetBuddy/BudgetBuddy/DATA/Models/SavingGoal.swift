// /Data/Models/SavingGoal.swift

import SwiftData
import Foundation

@Model
final class SavingGoal {
    var id: UUID
    var name: String
    var goalAmount: Decimal
    var currentAmount: Decimal
    var iconName: String?
    var colorHex: String?
    var descriptionText: String?
    var isArchived: Bool

    init(name: String, goalAmount: Decimal) {
        self.id = UUID()
        self.name = name
        self.goalAmount = goalAmount
        self.currentAmount = 0
        self.isArchived = false
    }

    var progress: Double {
        guard goalAmount > 0 else { return 0 }
        let a = NSDecimalNumber(decimal: currentAmount).doubleValue
        let g = NSDecimalNumber(decimal: goalAmount).doubleValue
        return max(0, min(1, a / g))
    }

    var effectiveIcon: String { iconName ?? "target" }
}
