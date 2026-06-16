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
    @State private var activeFilter: TxFilter = .all

    init(filterMonth: Date = Date()) {
        _currentMonth = State(initialValue: filterMonth)
    }

    enum TxFilter: String, CaseIterable {
        case all     = "Alles"
        case income  = "Inkomsten"
        case expense = "Uitgaven"
        case other   = "Overig"
    }

    private var currencyCode: String { settings.first?.currencyCode ?? "EUR" }

    private var monthTransactions: [Transaction] {
        allTransactions.filter {
            Calendar.current.isDate($0.date, equalTo: currentMonth, toGranularity: .month)
            && !$0.isRecurringTemplate
        }
    }

    private var filtered: [Transaction] {
        switch activeFilter {
        case .all:     return monthTransactions
        case .income:  return monthTransactions.filter { $0.type == .income }
        case .expense: return monthTransactions.filter { $0.type == .expense }
        case .other:   return monthTransactions.filter {
            $0.type == .transfer || $0.type == .savingDeposit || $0.type == .savingWithdrawal
        }
        }
    }

    private var totalIncome: Double {
        monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    private var totalExpenses: Double {
        monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    private var net: Double { totalIncome - totalExpenses }

    private var groupedByDay: [(day: Date, items: [Transaction])] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: filtered) { cal.startOfDay(for: $0.date) }
        return grouped.keys
            .sorted(by: >)
            .map { day in (day: day, items: grouped[day]!.sorted { $0.date > $1.date }) }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    heroCard
                        .padding(.horizontal)

                    filterPills
                        .padding(.horizontal)

                    if groupedByDay.isEmpty {
                        Text("Geen transacties voor \(currentMonth.formatted(.dateTime.month(.wide)))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 20) {
                            ForEach(groupedByDay, id: \.day) { group in
                                daySection(day: group.day, items: group.items)
                            }
                        }
                        .padding(.horizontal)
                    }

                    Color.clear.frame(height: 90)
                }
                .padding(.top, 8)
            }

            // FAB
            Button { showAddTransaction = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(Circle().fill(Color.black))
                    .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
            }
            .padding(.bottom, 24)
            .padding(.trailing, 20)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { moveMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { moveMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
        }
        .sheet(isPresented: $showAddTransaction) {
            AddEditTransactionView()
        }
    }

    // MARK: - Hero card (zelfde stijl als dashboard)

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Netto deze maand")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.55))

            Text(MoneyFormatter.format(net, currencyCode: currencyCode))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Spacer().frame(height: 16)

            HStack(spacing: 24) {
                heroStat(
                    label: "Inkomsten",
                    value: MoneyFormatter.format(totalIncome, currencyCode: currencyCode),
                    color: Color(red: 0.4, green: 0.9, blue: 0.65)
                )
                heroStat(
                    label: "Uitgaven",
                    value: MoneyFormatter.format(totalExpenses, currencyCode: currencyCode),
                    color: Color(red: 1, green: 0.45, blue: 0.45)
                )
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black)
        )
    }

    private func heroStat(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.45))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
        }
    }

    // MARK: - Filter pills

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TxFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.snappy(duration: 0.2)) { activeFilter = filter }
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(
                                    activeFilter == filter ? Color.black : Color(.secondarySystemBackground)
                                )
                            )
                            .foregroundStyle(activeFilter == filter ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Dag-sectie

    private func daySection(day: Date, items: [Transaction]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(dayLabel(for: day))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                let dayTotal = items.reduce(0.0) { acc, tx in
                    switch tx.type {
                    case .income:  return acc + tx.amount
                    case .expense: return acc - tx.amount
                    default:       return acc
                    }
                }
                if dayTotal != 0 {
                    Text((dayTotal > 0 ? "+" : "") + MoneyFormatter.format(dayTotal, currencyCode: currencyCode))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(dayTotal >= 0 ? .green : .red)
                }
            }

            VStack(spacing: 8) {
                ForEach(items) { tx in
                    NavigationLink {
                        TransactionDetailView(transaction: tx)
                    } label: {
                        txCard(tx)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func txCard(_ tx: Transaction) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(iconColor(for: tx))
                Image(systemName: iconName(for: tx))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(txTitle(tx))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                if let sub = txSubtitle(tx) {
                    Text(sub)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(txAmountString(tx))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(amountColor(for: tx))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Helpers

    private func txTitle(_ tx: Transaction) -> String {
        if let desc = tx.descriptionText, !desc.isEmpty { return desc }
        switch tx.type {
        case .income, .expense: return tx.category?.name ?? tx.type.uiTitle
        case .transfer:         return "Overboeking"
        case .savingDeposit:    return tx.savingGoal?.name ?? "Spaarpot"
        case .savingWithdrawal: return tx.savingGoal?.name ?? "Spaarpot"
        }
    }

    private func txSubtitle(_ tx: Transaction) -> String? {
        switch tx.type {
        case .income:
            return tx.destinationAccount?.name
        case .expense:
            let cat = tx.category?.name
            let desc = tx.descriptionText
            let account = tx.sourceAccount.map { "van \($0.name)" }
            if let desc, !desc.isEmpty, let cat { return "\(cat) · \(account ?? "")" }
            return account
        case .transfer:
            guard let s = tx.sourceAccount?.name, let d = tx.destinationAccount?.name else { return nil }
            return "\(s) → \(d)"
        case .savingDeposit:
            if let name = tx.sourceAccount?.name { return "van \(name)" }
            return nil
        case .savingWithdrawal:
            if let name = tx.destinationAccount?.name { return "naar \(name)" }
            return nil
        }
    }

    private func txAmountString(_ tx: Transaction) -> String {
        switch tx.type {
        case .income:  return "+" + MoneyFormatter.format(tx.amount, currencyCode: currencyCode)
        case .expense: return "-" + MoneyFormatter.format(tx.amount, currencyCode: currencyCode)
        default:       return MoneyFormatter.format(tx.amount, currencyCode: currencyCode)
        }
    }

    private func amountColor(for tx: Transaction) -> Color {
        switch tx.type {
        case .income:  return .green
        case .expense: return .red
        default:       return .secondary
        }
    }

    private func iconName(for tx: Transaction) -> String {
        if let cat = tx.category?.iconName, tx.type == .income || tx.type == .expense { return cat }
        switch tx.type {
        case .income:           return "arrow.down"
        case .expense:          return "arrow.up"
        case .transfer:         return "arrow.left.arrow.right"
        case .savingDeposit:    return "star.fill"
        case .savingWithdrawal: return "star"
        }
    }

    private func iconColor(for tx: Transaction) -> Color {
        if let hex = tx.category?.colorHex, let c = AppTheme.color(from: hex) { return c }
        return Color(white: 0.22)
    }

    private func dayLabel(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Vandaag" }
        if cal.isDateInYesterday(date) { return "Gisteren" }
        return date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))
    }

    private func moveMonth(by value: Int) {
        let cal = Calendar.current
        let base = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth)) ?? currentMonth
        if let next = cal.date(byAdding: .month, value: value, to: base) {
            withAnimation(.snappy) { currentMonth = next }
        }
    }
}
