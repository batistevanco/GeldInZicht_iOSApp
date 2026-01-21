//
//  DonutChartView.swift
//  BudgetBuddy
//
//  Created by Batiste Vancoillie on 20/01/2026.
//


// /Views/Components/DonutChartView.swift

import SwiftUI

struct DonutChartView: View {
    let slices: [DonutSlice]
    var lineWidth: CGFloat = 26

    private var total: Double {
        slices.reduce(0) { $0 + max(0, $1.value) }
    }

    var body: some View {
        ZStack {
            if total <= 0 {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: lineWidth)
            } else {
                ForEach(Array(slices.enumerated()), id: \.offset) { idx, slice in
                    Circle()
                        .trim(from: startTrim(for: idx), to: endTrim(for: idx))
                        .stroke(slice.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
            }

            Circle()
                .fill(Color(.systemBackground))
                .frame(width: 90, height: 90)
        }
        .frame(height: 180)
    }

    private func startTrim(for index: Int) -> CGFloat {
        guard total > 0 else { return 0 }
        let sumBefore = slices.prefix(index).reduce(0) { $0 + max(0, $1.value) }
        return CGFloat(sumBefore / total)
    }

    private func endTrim(for index: Int) -> CGFloat {
        guard total > 0 else { return 0 }
        let sumUpTo = slices.prefix(index + 1).reduce(0) { $0 + max(0, $1.value) }
        return CGFloat(sumUpTo / total)
    }
}