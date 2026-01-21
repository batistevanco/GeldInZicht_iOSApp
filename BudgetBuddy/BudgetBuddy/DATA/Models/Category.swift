// /Data/Models/Category.swift

import SwiftData
import Foundation

@Model
final class Category {
    var id: UUID
    var name: String
    var iconName: String
    var colorHex: String?
    var isDefault: Bool

    init(name: String, iconName: String, isDefault: Bool = true) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.isDefault = isDefault
    }
}
