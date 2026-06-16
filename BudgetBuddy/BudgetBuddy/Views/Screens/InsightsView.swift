// /Views/Screens/InsightsView.swift

import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query(sort: \Account.name) private var allAccounts: [Account]
    @Query private var settings: [AppSettings]

    @State private var currentMonth: Date = Date()

    private var currencyCode: String { settings.first?.currencyCode ?? "EUR" }
    private var cal: Calendar { .current }

    // MARK: - Month data

    private var monthTransactions: [Transaction] {
        allTransactions.filter {
            cal.isDate($0.date, equalTo: currentMonth, toGranularity: .month)
        }
    }

    private var totalIncome: Double {
        monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var totalExpenses: Double {
        monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var netBalance: Double { totalIncome - totalExpenses }

    private var totalSaved: Double {
        monthTransactions.filter { $0.type == .savingDeposit }.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Insights calculations

    private var expectedEnd: Double {
        FinanceEngine.expectedEndBalance(
            currentNet: netBalance,
            allTransactions: allTransactions,
            referenceDate: currentMonth
        )
    }

    private var pendingRecurring: [Transaction] {
        FinanceEngine.pendingRecurringThisMonth(
            allTransactions: allTransactions,
            referenceDate: currentMonth
        )
    }

    private var pendingExpenses: [Transaction] {
        pendingRecurring.filter { $0.type == .expense }
    }

    private var pendingExpensesTotal: Double {
        pendingExpenses.reduce(0) { $0 + $1.amount }
    }

    private var previousMonthNet: Double {
        guard let prevMonth = cal.date(byAdding: .month, value: -1, to: currentMonth) else { return 0 }
        let prev = allTransactions.filter { cal.isDate($0.date, equalTo: prevMonth, toGranularity: .month) }
        let inc = prev.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let exp = prev.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        return inc - exp
    }

    private var evolutionAmount: Double { netBalance - previousMonthNet }
    private var evolutionPositive: Bool { evolutionAmount >= 0 }

    private var biggestCategory: (name: String, icon: String, amount: Double, color: Color)? {
        let expenses = monthTransactions.filter { $0.type == .expense && $0.category != nil }
        var totals: [UUID: (name: String, icon: String, amount: Double, colorHex: String?)] = [:]
        for tx in expenses {
            guard let cat = tx.category else { continue }
            let current = totals[cat.id] ?? (cat.name, cat.iconName, 0, cat.colorHex)
            totals[cat.id] = (current.name, current.icon, current.amount + tx.amount, current.colorHex)
        }
        guard let top = totals.values.max(by: { $0.amount < $1.amount }) else { return nil }
        let color = AppTheme.color(from: top.colorHex) ?? AppTheme.brand
        return (top.name, top.icon, top.amount, color)
    }

    private var expensesByCategory: [(name: String, icon: String, amount: Double, color: Color, percent: Double)] {
        let expenses = monthTransactions.filter { $0.type == .expense && $0.category != nil }
        var totals: [UUID: (name: String, icon: String, amount: Double, colorHex: String?)] = [:]
        for tx in expenses {
            guard let cat = tx.category else { continue }
            let current = totals[cat.id] ?? (cat.name, cat.iconName, 0, cat.colorHex)
            totals[cat.id] = (current.name, current.icon, current.amount + tx.amount, current.colorHex)
        }
        let sorted = totals.values.sorted { $0.amount > $1.amount }
        let total = sorted.reduce(0) { $0 + $1.amount }
        return sorted.map { item in
            let color = AppTheme.color(from: item.colorHex) ?? AppTheme.brand
            let pct = total > 0 ? item.amount / total : 0
            return (item.name, item.icon, item.amount, color, pct)
        }
    }

    private var netWorthGrowth: Double {
        FinanceEngine.netWorthGrowth(
            accounts: allAccounts.filter { !$0.isArchived },
            allTransactions: allTransactions,
            referenceDate: currentMonth
        )
    }

    private var currentNetWorth: Double {
        FinanceEngine.netWorth(
            accounts: allAccounts.filter { !$0.isArchived },
            transactions: allTransactions
        )
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                monthPicker
                    .padding(.horizontal)

                // Section 1: Maandbalans
                sectionHeader("Maandbalans")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    bigInsightCard(
                        title: "Beschikbaar",
                        value: MoneyFormatter.format(netBalance, currencyCode: currencyCode),
                        subtitle: "tot nu toe",
                        icon: "eurosign.circle.fill",
                        iconColor: netBalance >= 0 ? .green : .red,
                        valueColor: netBalance >= 0 ? .green : .red
                    )
                    bigInsightCard(
                        title: "Verwacht eindsaldo",
                        value: MoneyFormatter.format(expectedEnd, currencyCode: currencyCode),
                        subtitle: "einde maand",
                        icon: "calendar.badge.clock",
                        iconColor: expectedEnd >= 0 ? AppTheme.brand : .red,
                        valueColor: expectedEnd >= 0 ? .primary : .red
                    )
                    bigInsightCard(
                        title: "Inkomen",
                        value: MoneyFormatter.format(totalIncome, currencyCode: currencyCode),
                        subtitle: "deze maand",
                        icon: "arrow.down.circle.fill",
                        iconColor: .green,
                        valueColor: .green
                    )
                    bigInsightCard(
                        title: "Uitgaven",
                        value: MoneyFormatter.format(totalExpenses, currencyCode: currencyCode),
                        subtitle: "deze maand",
                        icon: "arrow.up.circle.fill",
                        iconColor: .red,
                        valueColor: .red
                    )
                }
                .padding(.horizontal)

                // Section 2: Evolutie
                sectionHeader("Evolutie")
                HStack(spacing: 12) {
                    evolutionCard
                    savingsCard
                }
                .padding(.horizontal)

                // Section 3: Nog te betalen
                if !pendingExpenses.isEmpty {
                    sectionHeader("Nog te betalen deze maand")
                    pendingSection
                        .padding(.horizontal)
                }

                // Section 4: Uitgaven per categorie
                if !expensesByCategory.isEmpty {
                    sectionHeader("Uitgaven per categorie")
                    categoryBreakdown
                        .padding(.horizontal)
                }

                // Section 5: Netto vermogen
                sectionHeader("Netto vermogen")
                netWorthCard
                    .padding(.horizontal)

                Color.clear.frame(height: 20)
            }
            .padding(.top, 16)
        }
        .background(AppTheme.softBg)
        .navigationTitle("Inzichten")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Month picker

    private var monthPicker: some View {
        HStack {
            Button { moveMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(AppTheme.cardBg))
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 1) {
                Text(currentMonth.formatted(.dateTime.month(.wide)))
                    .font(.headline)
                Text(currentMonth.formatted(.dateTime.year()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button { moveMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(AppTheme.cardBg))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Section header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 4)
    }

    // MARK: - Big insight card

    private func bigInsightCard(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        valueColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.cardBg))
    }

    // MARK: - Evolution card

    private var evolutionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: evolutionPositive ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                    .foregroundStyle(evolutionPositive ? .green : .red)
                Text("t.o.v. vorige maand")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text((evolutionPositive ? "+" : "") + MoneyFormatter.format(evolutionAmount, currencyCode: currencyCode))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(evolutionPositive ? .green : .red)

            if previousMonthNet != 0 {
                let pct = abs(evolutionAmount / previousMonthNet) * 100
                Text(String(format: "%@%.0f%%", evolutionPositive ? "+" : "-", pct))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.cardBg))
    }

    // MARK: - Savings card

    private var savingsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "star.circle.fill")
                    .foregroundStyle(.orange)
                Text("Gespaard")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(MoneyFormatter.format(totalSaved, currencyCode: currencyCode))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(totalSaved > 0 ? .orange : .secondary)

            Text("deze maand")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.cardBg))
    }

    // MARK: - Pending section

    private var pendingSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(pendingExpenses.enumerated()), id: \.element.id) { idx, tx in
                HStack(spacing: 12) {
                    Image(systemName: tx.category?.iconName ?? "repeat.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(AppTheme.color(from: tx.category?.colorHex) ?? .gray))

                    Text(tx.descriptionText ?? tx.category?.name ?? tx.type.uiTitle)
                        .font(.subheadline)

                    Spacer()

                    Text("–" + MoneyFormatter.format(tx.amount, currencyCode: currencyCode))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                if idx < pendingExpenses.count - 1 {
                    Divider().padding(.leading, 54)
                }
            }

            Divider()

            HStack {
                Text("Totaal nog te betalen")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("–" + MoneyFormatter.format(pendingExpensesTotal, currencyCode: currencyCode))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.red)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.cardBg))
    }

    // MARK: - Category breakdown

    private var categoryBreakdown: some View {
        VStack(spacing: 0) {
            ForEach(Array(expensesByCategory.enumerated()), id: \.offset) { idx, item in
                VStack(spacing: 6) {
                    HStack(spacing: 12) {
                        Image(systemName: item.icon)
                            .font(.system(size: 13))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(item.color))

                        Text(item.name)
                            .font(.subheadline)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 1) {
                            Text(MoneyFormatter.format(item.amount, currencyCode: currencyCode))
                                .font(.subheadline.weight(.semibold))
                            Text(String(format: "%.0f%%", item.percent * 100))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.color.opacity(0.15))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.color)
                                .frame(width: geo.size.width * item.percent, height: 4)
                        }
                    }
                    .frame(height: 4)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

                if idx < expensesByCategory.count - 1 {
                    Divider().padding(.leading, 54)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.cardBg))
    }

    // MARK: - Net worth card

    private var netWorthCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Huidig vermogen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(MoneyFormatter.format(currentNetWorth, currencyCode: currencyCode))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Groei deze maand")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: netWorthGrowth >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(netWorthGrowth >= 0 ? .green : .red)
                        Text((netWorthGrowth >= 0 ? "+" : "") + MoneyFormatter.format(netWorthGrowth, currencyCode: currencyCode))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(netWorthGrowth >= 0 ? .green : .red)
                    }
                }
            }

            NavigationLink {
                NetWorthOverviewView()
            } label: {
                Text("Bekijk volledig overzicht")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.brand)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.cardBg))
    }

    // MARK: - Helpers

    private func moveMonth(by value: Int) {
        let base = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth)) ?? currentMonth
        if let next = cal.date(byAdding: .month, value: value, to: base) {
            withAnimation(.snappy) { currentMonth = next }
        }
    }
}
