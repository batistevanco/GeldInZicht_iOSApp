//
//  TransactionsListView.swift
//  BudgetBuddy
//
//  Created by Batiste Vancoillie on 20/01/2026.
//


import SwiftUI

struct TransactionsListView: View {
    let transactions: [Transaction]

    var body: some View {
        if transactions.isEmpty {
            EmptyStateView(
                icon: "tray",
                title: "Geen transacties",
                message: "Voeg je eerste transactie toe"
            )
        } else {
            List {
                ForEach(transactions) { transaction in
                    NavigationLink {
                        TransactionDetailView(transaction: transaction)
                    } label: {
                        TransactionRowView(transaction: transaction)
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}
