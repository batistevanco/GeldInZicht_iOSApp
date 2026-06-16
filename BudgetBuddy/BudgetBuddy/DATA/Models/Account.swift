// /Data/Models/Account.swift

import SwiftData
import Foundation

@Model
final class Account {
    var id: UUID = UUID()
    var name: String = ""
    var type: AccountType = AccountType.checking
    var initialBalance: Double = 0.0
    var iconName: String?
    var colorHex: String?
    var isArchived: Bool = false
    var isDefault: Bool = false

    init(name: String, type: AccountType, initialBalance: Double) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.initialBalance = initialBalance
        self.isArchived = false
    }

    var effectiveIcon: String { iconName ?? type.defaultIcon }
}
