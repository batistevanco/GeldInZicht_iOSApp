//
//  SavingGoalCardView.swift
//  BudgetBuddy
//
//  Created by Batiste Vancoillie on 20/01/2026.
//


// /Views/Components/SavingGoalCardView.swift

import SwiftUI

struct SavingGoalCardView: View {
    let goal: SavingGoal
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle().fill(AppTheme.color(from: goal.colorHex) ?? AppTheme.brand.opacity(0.18))
                    Image(systemName: goal.effectiveIcon)
                        .foregroundStyle(AppTheme.brand)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                        .font(.headline)
                    Text("\(MoneyFormatter.format(goal.currentAmount, currencyCode: currencyCode)) / \(MoneyFormatter.format(goal.goalAmount, currencyCode: currencyCode))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            ProgressView(value: goal.progress)
                .tint(AppTheme.mint)
        }
        .padding(14)
        .background(AppTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}