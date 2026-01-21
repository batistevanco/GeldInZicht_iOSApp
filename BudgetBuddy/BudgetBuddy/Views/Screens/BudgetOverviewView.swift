import SwiftUI
import SwiftData

struct BudgetOverviewView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \Transaction.date, order: .reverse)
    private var allTransactions: [Transaction]

    @Query private var settings: [AppSettings]

    @State private var currentMonth: Date = Date()
    @State private var showAddTransaction = false

    private var currencyCode: String {
        settings.first?.currencyCode ?? "EUR"
    }

    // MARK: - Filtered data

    private var monthTransactions: [Transaction] {
        allTransactions.filter {
            Calendar.current.isDate($0.date, equalTo: currentMonth, toGranularity: .month)
        }
    }

    private var totalIncome: Decimal {
        monthTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }

    private var totalExpenses: Decimal {
        monthTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    private var netBalance: Decimal {
        totalIncome - totalExpenses
    }

    // MARK: - UI

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {

                // 🔝 Header OUTSIDE the List (prevents tap issues + keeps it at the top edge)
                header
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .background(Color(.systemBackground))

                // 🧾 Transactions list
                List {
                    Section(header: Text("Transacties")) {
                        if monthTransactions.isEmpty {
                            EmptyStateView(
                                icon: "tray",
                                title: "Geen transacties",
                                message: "Voeg een transactie toe voor deze maand"
                            )
                            .padding(.vertical, 24)
                            .listRowSeparator(.hidden)
                        } else {
                            ForEach(monthTransactions) { tx in
                                NavigationLink {
                                    TransactionDetailView(transaction: tx)
                                } label: {
                                    TransactionRowView(
                                        transaction: tx,
                                        currencyCode: currencyCode
                                    )
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }

            // ➕ FAB pinned above tab bar
            FloatingActionButton {
                showAddTransaction = true
            }
            .padding(.bottom, 14)
        }
        .sheet(isPresented: $showAddTransaction) {
            AddEditTransactionView()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 16) {
            Text("Jouw budget")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            monthSelector

            Text(MoneyFormatter.format(netBalance, currencyCode: currencyCode))
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(netBalance >= 0 ? .green : .red)

            HStack {
                summaryItem("In", totalIncome, .green)
                summaryItem("Uit", totalExpenses, .red)
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Month selector

    private var monthSelector: some View {
        HStack {
            Button {
                moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)

            Spacer()

            Button {
                moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func moveMonth(by value: Int) {
        let cal = Calendar.current
        let base = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth)) ?? currentMonth
        if let next = cal.date(byAdding: .month, value: value, to: base) {
            withAnimation(.snappy) {
                currentMonth = next
            }
        }
    }

    // MARK: - Helpers

    private func summaryItem(_ title: String, _ value: Decimal, _ color: Color) -> some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(MoneyFormatter.format(value, currencyCode: currencyCode))
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}
