//
//  FloatingActionButton 2.swift
//  BudgetBuddy
//
//  Created by Batiste Vancoillie on 20/01/2026.
//


// /Views/Components/FloatingActionButton.swift

import SwiftUI

struct FloatingActionButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(AppTheme.brand)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 62, height: 62)
            .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
        }
        .accessibilityLabel("Nieuwe transactie")
        .padding(.bottom, 10)
    }
}
