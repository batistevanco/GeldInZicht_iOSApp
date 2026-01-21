// /Data/Models/Account.swift

import SwiftData
import Foundation

@Model
final class Account {
    var id: UUID
    var name: String
    var type: AccountType
    var initialBalance: Decimal
    var iconName: String?
    var colorHex: String?
    var isArchived: Bool
    var isDefault: Bool = false

    init(name: String, type: AccountType, initialBalance: Decimal) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.initialBalance = initialBalance
        self.isArchived = false
    }

    var effectiveIcon: String { iconName ?? type.defaultIcon }
}
