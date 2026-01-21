//
//  AccountDetailView.swift
//  BudgetBuddy
//
//  Created by Batiste Vancoillie on 20/01/2026.
//


// /Views/Screens/AccountDetailView.swift

import SwiftUI
import SwiftData

struct AccountDetailView: View {
    let account: Account

    @Environment(\.modelContext) private var context
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query private var settings: [AppSettings]

    @State private var showAddIncome = false
    @State private var showAddExpense = false
    @State private var showTransfer = false
    @State private var showEditAccount = false

    private var currencyCode: String { settings.first?.currencyCode ?? "EUR" }

    private var txs: [Transaction] {
        allTransactions.filter { tx in
            tx.isRecurringTemplate == false &&
            (tx.sourceAccount?.id == account.id || tx.destinationAccount?.id == account.id)
        }
    }

    private func setAsDefaultAccount() {
        let allAccounts = (try? context.fetch(FetchDescriptor<Account>())) ?? []

        for acc in allAccounts {
            acc.isDefault = (acc.id == account.id)
        }

        try? context.save()
    }

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 6) {
                Text(account.name)
                    .font(.title.bold())
                Text(
                    MoneyFormatter.format(
                        FinanceEngine.accountBalance(account, transactions: allTransactions),
                        currencyCode: currencyCode
                    )
                )
                    .font(.title2.weight(.semibold))
            }
            Toggle(
                "Standaardrekening",
                isOn: Binding(
                    get: { account.isDefault },
                    set: { newValue in
                        if newValue {
                            setAsDefaultAccount()
                        } else {
                            // ❗ voorkom dat er géén standaardrekening is
                            account.isDefault = true
                            try? context.save()
                        }
                    }
                )
            )
            .padding(.horizontal)
            .padding(.top, 10)

            HStack(spacing: 10) {
                PrimaryButton(title: "Storten", systemImage: "arrow.down.circle") { showAddIncome = true }
                PrimaryButton(title: "Opnemen", systemImage: "arrow.up.circle") { showAddExpense = true }
            }
            .padding(.horizontal)

            PrimaryButton(title: "Overboeken", systemImage: "arrow.left.arrow.right") { showTransfer = true }
                .padding(.horizontal)

            if txs.isEmpty {
                EmptyStateView(icon: "tray", title: "Geen transacties", message: "Voeg een storting/opname toe")
                    .padding(.top, 16)
            } else {
                List {
                    ForEach(txs) { tx in
                        NavigationLink {
                            TransactionDetailView(transaction: tx)
                        } label: {
                            TransactionRowView(transaction: tx, currencyCode: currencyCode)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Rekening")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Bewerken") {
                    showEditAccount = true
                }
            }
        }
        .sheet(isPresented: $showAddIncome) {
            AddEditTransactionView(preset: .income(on: account))
        }
        .sheet(isPresented: $showAddExpense) {
            AddEditTransactionView(preset: .expense(from: account))
        }
        .sheet(isPresented: $showTransfer) {
            AddEditTransactionView(preset: .transfer(from: account))
        }
        .sheet(isPresented: $showEditAccount) {
            AddEditAccountView(account: account)
        }
    }
}
