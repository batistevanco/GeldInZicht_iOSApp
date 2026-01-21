import SwiftUI

struct TransactionDetailView: View {
    let transaction: Transaction

    @State private var showEdit = false

    var body: some View {
        Form {
            Section(header: FormSectionHeader(title: "Details")) {
                row("Type", transaction.type.rawValue.capitalized)
                row("Bedrag", MoneyFormatter.format(transaction.amount))
                row("Datum", transaction.date.formatted(date: .long, time: .omitted))

                if let desc = transaction.descriptionText {
                    row("Omschrijving", desc)
                }
            }
        }
        .navigationTitle("Transactie")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Bewerken") {
                    showEdit = true
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            NavigationStack {
                AddEditTransactionView(transaction: transaction)
            }
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}
