// /Views/Screens/FinancialTimelineView.swift

import SwiftUI
import SwiftData

struct FinancialTimelineView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query private var settings: [AppSettings]

    @State private var filterType: FilterType = .all

    private var currencyCode: String { settings.first?.currencyCode ?? "EUR" }

    enum FilterType: String, CaseIterable {
        case all = "Alles"
        case income = "Inkomsten"
        case expense = "Uitgaven"
        case saving = "Sparen"
    }

    private var filteredTransactions: [Transaction] {
        let nonTemplates = allTransactions.filter { !$0.isRecurringTemplate }
        switch filterType {
        case .all:     return nonTemplates
        case .income:  return nonTemplates.filter { $0.type == .income }
        case .expense: return nonTemplates.filter { $0.type == .expense }
        case .saving:  return nonTemplates.filter { $0.type == .savingDeposit || $0.type == .savingWithdrawal }
        }
    }

    private var groupedByMonth: [(key: String, sortKey: Date, transactions: [Transaction])] {
        let cal = Calendar.current
        var groups: [Date: [Transaction]] = [:]

        for tx in filteredTransactions {
            let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: tx.date)) ?? tx.date
            groups[monthStart, default: []].append(tx)
        }

        return groups.map { (key: monthLabel($0.key), sortKey: $0.key, transactions: $0.value) }
            .sorted { $0.sortKey > $1.sortKey }
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))

            if filteredTransactions.isEmpty {
                Spacer()
                EmptyStateView(icon: "clock", title: "Geen transacties", message: "")
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                        ForEach(groupedByMonth, id: \.sortKey) { group in
                            Section {
                                VStack(spacing: 0) {
                                    ForEach(Array(group.transactions.enumerated()), id: \.element.id) { idx, tx in
                                        NavigationLink {
                                            TransactionDetailView(transaction: tx)
                                        } label: {
                                            timelineRow(tx, isLast: idx == group.transactions.count - 1)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.cardBg))
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                            } header: {
                                Text(group.key)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.softBg)
                            }
                        }
                        Color.clear.frame(height: 20)
                    }
                    .padding(.top, 8)
                }
                .background(AppTheme.softBg)
            }
        }
        .navigationTitle("Tijdlijn")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FilterType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.snappy) { filterType = type }
                    } label: {
                        Text(type.rawValue)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(filterType == type ? AppTheme.brand : Color(.tertiarySystemBackground))
                            )
                            .foregroundStyle(filterType == type ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Timeline row

    private func timelineRow(_ tx: Transaction, isLast: Bool) -> some View {
        HStack(spacing: 12) {
            // Timeline line + dot
            VStack(spacing: 0) {
                Circle()
                    .fill(typeColor(tx))
                    .frame(width: 10, height: 10)
                if !isLast {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 10)
            .padding(.leading, 14)
            .padding(.vertical, 14)

            // Content
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(txTitle(tx))
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    Text(tx.date.formatted(.dateTime.day().month(.wide)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(txAmountString(tx))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(typeColor(tx))
                    Text(tx.type.uiTitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.trailing, 14)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Helpers

    private func txTitle(_ tx: Transaction) -> String {
        tx.descriptionText?.isEmpty == false ? tx.descriptionText! :
        tx.category?.name ?? tx.type.uiTitle
    }

    private func txAmountString(_ tx: Transaction) -> String {
        let prefix: String
        switch tx.type {
        case .income:           prefix = "+"
        case .expense:          prefix = "–"
        case .transfer:         prefix = "↔"
        case .savingDeposit:    prefix = "→"
        case .savingWithdrawal: prefix = "←"
        }
        return prefix + MoneyFormatter.format(tx.amount, currencyCode: currencyCode)
    }

    private func typeColor(_ tx: Transaction) -> Color {
        switch tx.type {
        case .income:           return .green
        case .expense:          return .red
        case .transfer:         return .blue
        case .savingDeposit:    return .orange
        case .savingWithdrawal: return .purple
        }
    }

    private func monthLabel(_ date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }
}
