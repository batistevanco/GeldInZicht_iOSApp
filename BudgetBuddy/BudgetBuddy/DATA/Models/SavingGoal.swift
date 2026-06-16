// /Data/Models/SavingGoal.swift

import SwiftData
import Foundation

@Model
final class SavingGoal {
    var id: UUID = UUID()
    var name: String = ""
    var goalAmount: Double = 0.0
    var currentAmount: Double = 0.0
    var iconName: String?
    var colorHex: String?
    var descriptionText: String?
    var isArchived: Bool = false

    init(name: String, goalAmount: Double) {
        self.id = UUID()
        self.name = name
        self.goalAmount = goalAmount
        self.currentAmount = 0
        self.isArchived = false
    }

    var progress: Double {
        guard goalAmount > 0 else { return 0 }
        return max(0, min(1, currentAmount / goalAmount))
    }

    var effectiveIcon: String { iconName ?? "target" }
}
