//
//  FormSectionHeader.swift
//  BudgetBuddy
//
//  Created by Batiste Vancoillie on 20/01/2026.
//


// /Views/Components/FormSectionHeader.swift

import SwiftUI

struct FormSectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.top, 6)
    }
}