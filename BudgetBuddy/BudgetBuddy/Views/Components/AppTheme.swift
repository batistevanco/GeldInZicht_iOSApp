// /Views/Components/AppTheme.swift

import SwiftUI

enum AppTheme {

    // ⚫️ HOOFDKLEUR
    static let brand = Color(red: 0.10, green: 0.12, blue: 0.18)
    // Hex ≈ #1A1F2E  (donker antraciet – past bij het zwarte thema)

    // Secundair accent
    static let accent = Color(red: 0.22, green: 0.25, blue: 0.32)

    // Statuskleuren
    static let positive = Color.green
    static let negative = Color.red

    // Achtergronden
    static let softBg = Color(.systemGroupedBackground)
    static let cardBg = Color(.secondarySystemGroupedBackground)
    
    static let mint = Color(red: 0.35, green: 0.83, blue: 0.75)

    // HEX → Color helper
    static func color(from hex: String?) -> Color? {
        guard let hex else { return nil }
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = Int(s, radix: 16) else { return nil }

        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8) & 0xFF) / 255
        let b = Double(v & 0xFF) / 255
        return Color(red: r, green: g, blue: b)
    }
}
