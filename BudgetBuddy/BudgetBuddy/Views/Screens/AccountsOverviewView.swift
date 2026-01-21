import SwiftUI
import SwiftData

struct AccountsOverviewView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Account.name) private var accounts: [Account]
    @Query private var transactions: [Transaction]
    @Query private var settings: [AppSettings]

    @State private var showAdd = false

    private var currencyCode: String { settings.first?.currencyCode ?? "EUR" }
    private var activeAccounts: [Account] { accounts.filter { !$0.isArchived } }

    private var netWorth: Decimal {
        FinanceEngine.netWorth(
            accounts: activeAccounts,
            transactions: transactions
        )
    }

    var body: some View {
        List {

            // 🔗 Spaarpotjes link
            Section {
                NavigationLink {
                    SavingGoalsOverviewView()
                } label: {
                    HStack {
                        Image(systemName: "target")
                        Text("Spaarpotjes")
                            .font(.headline)
                    }
                    .padding(.vertical, 6)
                }
            }

            // 💰 Net worth
            Section {
                VStack(spacing: 6) {
                    Text("Totaal vermogen")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(MoneyFormatter.format(netWorth, currencyCode: currencyCode))
                        .font(.title.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listRowSeparator(.hidden)

            // 💳 Accounts
            Section {
                if activeAccounts.isEmpty {
                    EmptyStateView(
                        icon: "creditcard",
                        title: "Geen rekeningen",
                        message: "Maak je eerste rekening aan"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    ForEach(activeAccounts) { acc in
                        NavigationLink {
                            AccountDetailView(account: acc)
                        } label: {
                            AccountCardView(account: acc, currencyCode: currencyCode)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteAccounts)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Rekeningen")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddEditAccountView()
        }
    }

    // MARK: - Delete

    private func deleteAccounts(at offsets: IndexSet) {
        // Welke accounts worden verwijderd?
        let toDelete = offsets.map { activeAccounts[$0] }
        let deletingDefault = toDelete.contains(where: { $0.isDefault })

        // Delete
        toDelete.forEach { context.delete($0) }

        // Als de standaardrekening verwijderd werd: wijs een nieuwe default toe (eerste actieve rekening)
        if deletingDefault {
            let remaining = (try? context.fetch(FetchDescriptor<Account>())) ?? []
            if let newDefault = remaining.first(where: { !$0.isArchived }) {
                // Zorg dat er maar één default is
                for acc in remaining {
                    acc.isDefault = (acc.id == newDefault.id)
                }
            }
        }

        try? context.save()
    }
}
