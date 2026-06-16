// /Data/Models/Category.swift

import SwiftData
import Foundation

@Model
final class Category {
    var id: UUID = UUID()
    var name: String = ""
    var iconName: String = "tag"
    var colorHex: String?
    var isDefault: Bool = true

    init(name: String, iconName: String, isDefault: Bool = true) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.isDefault = isDefault
    }
}
