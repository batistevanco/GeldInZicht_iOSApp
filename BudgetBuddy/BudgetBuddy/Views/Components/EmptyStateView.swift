//
//  EmptyStateView.swift
//  BudgetBuddy
//
//  Created by Batiste Vancoillie on 20/01/2026.
//


// /Views/Components/EmptyStateView.swift

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var ctaTitle: String? = nil
    var onCTA: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(AppTheme.brand)

            Text(title)
                .font(.title3.bold())

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let ctaTitle, let onCTA {
                PrimaryButton(title: ctaTitle, action: onCTA)
                    .padding(.top, 6)
            }
        }
        .padding(24)
        .frame(maxWidth: 520)
        .background(AppTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding()
    }
}