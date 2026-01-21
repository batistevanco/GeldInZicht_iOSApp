//
//  ExpenseBreakdownView.swift
//  BudgetBuddy
//
//  Created by Batiste Vancoillie on 20/01/2026.
//


// /Views/Screens/ExpenseBreakdownView.swift

import SwiftUI
import SwiftData

struct ExpenseBreakdownView: View {
    @Query private var settings: [AppSettings]

    let transactions: [Transaction]

    private var currencyCode: String { settings.first?.currencyCode ?? "EUR" }

    private var expenseTxs: [Transaction] {
        transactions.filter { $0.type == .expense && $0.isRecurringTemplate == false }
    }

    private var total: Decimal {
        expenseTxs.reduce(0 as Decimal) { $0 + $1.amount }
    }

    private var slices: [DonutSlice] {
        let grouped = Dictionary(grouping: expenseTxs, by: { $0.category?.name ?? "Overig" })
        let colors: [Color] = [.purple, .mint, .blue, .orange, .pink, .teal, .indigo, .yellow]

        return grouped.keys.sorted().enumerated().map { idx, key in
            let sum = grouped[key]!.reduce(0.0) { $0 + NSDecimalNumber(decimal: $1.amount).doubleValue }
            return DonutSlice(label: key, value: sum, color: colors[idx % colors.count])
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("Totaal uitgaven")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(MoneyFormatter.format(total, currencyCode: currencyCode))
                        .font(.title.bold())
                        .foregroundStyle(.red)
                }

                DonutChartView(slices: slices)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(expenseTxs) { tx in
                        TransactionRowView(transaction: tx, currencyCode: currencyCode)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Uitgaven")
        .navigationBarTitleDisplayMode(.inline)
    }
}