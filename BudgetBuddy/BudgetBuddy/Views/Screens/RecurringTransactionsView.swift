// /Views/Screens/RecurringTransactionsView.swift

import SwiftUI
import SwiftData

struct RecurringTransactionsView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \Transaction.date, order: .reverse)
    private var allTransactions: [Transaction]

    @Query private var settings: [AppSettings]

    @State private var showAdd = false
    @State private var toDelete: Transaction?

    private var currencyCode: String { settings.first?.currencyCode ?? "EUR" }

    private var templates: [Transaction] {
        allTransactions.filter { $0.isRecurringTemplate }.sorted { $0.date > $1.date }
    }

    private var incomeTemplates: [Transaction] { templates.filter { $0.type == .income } }
    private var expenseTemplates: [Transaction] { templates.filter { $0.type == .expense } }

    private var monthlyTotal: Decimal {
        templates.reduce(0) { result, tx in
            let monthly = monthlyEquivalent(tx)
            return tx.type == .income ? result + monthly : result - monthly
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !templates.isEmpty {
                    summaryCard
                        .padding(.horizontal)
                }

                if templates.isEmpty {
                    EmptyStateView(
                        icon: "repeat.circle",
                        title: "Geen terugkerende transacties",
                        message: "Voeg een terugkerende inkomst of uitgave toe"
                    )
                    .padding(.top, 60)
                } else {
                    if !incomeTemplates.isEmpty {
                        group(title: "Inkomsten", templates: incomeTemplates, color: .green)
                    }
                    if !expenseTemplates.isEmpty {
                        group(title: "Uitgaven", templates: expenseTemplates, color: .red)
                    }
                }

                Color.clear.frame(height: 80)
            }
            .padding(.top, 16)
        }
        .background(AppTheme.softBg)
        .navigationTitle("Terugkerend")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddEditTransactionView()
        }
        .alert("Verwijderen?", isPresented: Binding(
            get: { toDelete != nil },
            set: { if !$0 { toDelete = nil } }
        )) {
            Button("Verwijderen", role: .destructive) {
                if let tx = toDelete { context.delete(tx) }
                toDelete = nil
            }
            Button("Annuleren", role: .cancel) { toDelete = nil }
        } message: {
            Text("Deze terugkerende transactie en alle toekomstige herhalingen worden gestopt.")
        }
    }

    // MARK: - Summary card

    private var summaryCard: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("Maandelijks netto")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
                Text((monthlyTotal >= 0 ? "+" : "") + MoneyFormatter.format(monthlyTotal, currencyCode: currencyCode))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)

            Divider().background(.white.opacity(0.3)).frame(height: 40)

            VStack(spacing: 4) {
                Text("Actief")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
                Text("\(templates.count)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(LinearGradient(
                    colors: [AppTheme.brand, Color(red: 0.18, green: 0.28, blue: 0.98)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .shadow(color: AppTheme.brand.opacity(0.35), radius: 14, y: 6)
    }

    // MARK: - Group section

    private func group(title: String, templates: [Transaction], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(Array(templates.enumerated()), id: \.element.id) { idx, tx in
                    recurringRow(tx, color: color)
                    if idx < templates.count - 1 {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.cardBg))
            .padding(.horizontal)
        }
    }

    private func recurringRow(_ tx: Transaction, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.12))
                Image(systemName: tx.category?.iconName ?? (tx.type == .income ? "arrow.down" : "arrow.up"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(tx.descriptionText ?? tx.category?.name ?? tx.type.uiTitle)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "repeat")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(tx.frequency.uiLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text("Volgende: \(nextOccurrenceString(tx))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text((color == .red ? "–" : "+") + MoneyFormatter.format(tx.amount, currencyCode: currencyCode))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
                Text(monthlyEquivalentLabel(tx))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { toDelete = tx } label: {
                Label("Verwijder", systemImage: "trash")
            }
        }
    }

    // MARK: - Helpers

    private func nextOccurrenceString(_ tx: Transaction) -> String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var cursor = cal.startOfDay(for: tx.date)

        for _ in 0..<500 {
            guard let next = advance(cursor, by: tx.frequency) else { break }
            cursor = next
            if cursor >= today {
                return cursor.formatted(.dateTime.day().month(.abbreviated))
            }
        }
        return "–"
    }

    private func monthlyEquivalent(_ tx: Transaction) -> Decimal {
        switch tx.frequency {
        case .none:        return 0
        case .weekly:      return tx.amount * 4
        case .monthly:     return tx.amount
        case .quarterly:   return tx.amount / 3
        case .fourMonthly: return tx.amount / 4
        case .sixMonthly:  return tx.amount / 6
        case .yearly:      return tx.amount / 12
        }
    }

    private func monthlyEquivalentLabel(_ tx: Transaction) -> String {
        guard tx.frequency != .monthly else { return "" }
        let m = monthlyEquivalent(tx)
        return "≈ \(MoneyFormatter.format(m, currencyCode: currencyCode))/mnd"
    }

    private func advance(_ date: Date, by freq: TransactionFrequency) -> Date? {
        let cal = Calendar.current
        switch freq {
        case .weekly:      return cal.date(byAdding: .weekOfYear, value: 1, to: date)
        case .monthly:     return cal.date(byAdding: .month, value: 1, to: date)
        case .quarterly:   return cal.date(byAdding: .month, value: 3, to: date)
        case .fourMonthly: return cal.date(byAdding: .month, value: 4, to: date)
        case .sixMonthly:  return cal.date(byAdding: .month, value: 6, to: date)
        case .yearly:      return cal.date(byAdding: .year, value: 1, to: date)
        case .none:        return nil
        }
    }
}
