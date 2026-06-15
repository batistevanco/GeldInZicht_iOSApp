// /Views/Screens/TransactionsListView.swift

import SwiftUI
import SwiftData

struct TransactionsListView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \Transaction.date, order: .reverse)
    private var allTransactions: [Transaction]

    @Query private var settings: [AppSettings]

    @State private var currentMonth: Date
    @State private var showAddTransaction = false

    init(filterMonth: Date = Date()) {
        _currentMonth = State(initialValue: filterMonth)
    }

    private var currencyCode: String { settings.first?.currencyCode ?? "EUR" }

    private var monthTransactions: [Transaction] {
        allTransactions.filter {
            Calendar.current.isDate($0.date, equalTo: currentMonth, toGranularity: .month)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                monthSelector
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))

                if monthTransactions.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "tray",
                        title: "Geen transacties",
                        message: "Voeg een transactie toe voor deze maand"
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(monthTransactions) { tx in
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

            FloatingActionButton { showAddTransaction = true }
                .padding(.bottom, 14)
        }
        .navigationTitle("Transacties")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddTransaction) {
            AddEditTransactionView()
        }
    }

    private var monthSelector: some View {
        HStack {
            Button { moveMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color(.tertiarySystemBackground)))
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 0) {
                Text(currentMonth.formatted(.dateTime.month(.wide)))
                    .font(.headline.bold())
                Text(currentMonth.formatted(.dateTime.year()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color(.secondarySystemBackground)))

            Spacer()

            Button { moveMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color(.tertiarySystemBackground)))
            }
            .buttonStyle(.plain)
        }
    }

    private func moveMonth(by value: Int) {
        let cal = Calendar.current
        let base = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth)) ?? currentMonth
        if let next = cal.date(byAdding: .month, value: value, to: base) {
            withAnimation(.snappy) { currentMonth = next }
        }
    }
}
