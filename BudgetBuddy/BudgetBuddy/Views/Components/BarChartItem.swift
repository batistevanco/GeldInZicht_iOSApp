//
//  BarChartItem.swift
//  BudgetBuddy
//
//  Created by Batiste Vancoillie on 20/01/2026.
//


// /Views/Components/BarChartView.swift

import SwiftUI

struct BarChartItem: Identifiable {
    let id = UUID()
    let label: String
    let income: Double
    let expense: Double
}

struct BarChartView: View {
    let items: [BarChartItem]

    private var maxValue: Double {
        max(1, items.map { max($0.income, $0.expense) }.max() ?? 1)
    }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(items) { it in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(it.label).font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("In \(Int(it.income)) · Uit \(Int(it.expense))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    GeometryReader { geo in
                        let w = geo.size.width
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.secondary.opacity(0.12))
                                .frame(height: 12)

                            RoundedRectangle(cornerRadius: 10)
                                .fill(.green.opacity(0.55))
                                .frame(width: w * (it.income / maxValue), height: 12)

                            RoundedRectangle(cornerRadius: 10)
                                .fill(.red.opacity(0.45))
                                .frame(width: w * (it.expense / maxValue), height: 12)
                                .blendMode(.multiply)
                        }
                    }
                    .frame(height: 12)
                }
                .padding(.vertical, 4)
            }
        }
    }
}