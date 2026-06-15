// /Views/Screens/DashboardView.swift

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \Transaction.date, order: .reverse)
    private var allTransactions: [Transaction]

    @Query private var allAccounts: [Account]
    @Query private var allGoals: [SavingGoal]
    @Query private var settings: [AppSettings]

    @State private var currentMonth: Date = Date()
    @State private var showAddTransaction = false

    private var currencyCode: String { settings.first?.currencyCode ?? "EUR" }

    // MARK: - Computed values

    private var monthTransactions: [Transaction] {
        allTransactions.filter {
            Calendar.current.isDate($0.date, equalTo: currentMonth, toGranularity: .month)
        }
    }

    private var totalIncome: Decimal {
        monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var totalExpenses: Decimal {
        monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var netBalance: Decimal { totalIncome - totalExpenses }

    private var totalSaved: Decimal {
        monthTransactions.filter { $0.type == .savingDeposit }.reduce(0) { $0 + $1.amount }
    }

    private var biggestCategory: (name: String, icon: String, amount: Decimal)? {
        let expenses = monthTransactions.filter { $0.type == .expense && $0.category != nil }
        var totals: [UUID: (name: String, icon: String, amount: Decimal)] = [:]
        for tx in expenses {
            guard let cat = tx.category else { continue }
            let current = totals[cat.id] ?? (cat.name, cat.iconName ?? "tag", 0)
            totals[cat.id] = (current.name, current.icon, current.amount + tx.amount)
        }
        return totals.values.max(by: { $0.amount < $1.amount })
    }

    private var previousMonthNet: Decimal {
        let cal = Calendar.current
        guard let prevMonth = cal.date(byAdding: .month, value: -1, to: currentMonth) else { return 0 }
        let prev = allTransactions.filter {
            cal.isDate($0.date, equalTo: prevMonth, toGranularity: .month)
        }
        let inc = prev.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let exp = prev.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        return inc - exp
    }

    private var evolutionAmount: Decimal { netBalance - previousMonthNet }
    private var evolutionPositive: Bool { evolutionAmount >= 0 }

    private var recentTransactions: [Transaction] {
        Array(monthTransactions.prefix(5))
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                        .padding(.horizontal)

                    insightsRow
                        .padding(.horizontal)

                    NavigationLink {
                        InsightsView()
                    } label: {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                            Text("Alle inzichten bekijken")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.cardBg))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    recentSection
                        .padding(.horizontal)

                    Color.clear.frame(height: 80)
                }
                .padding(.top, 16)
            }
            .background(AppTheme.softBg)

            FloatingActionButton { showAddTransaction = true }
                .padding(.bottom, 14)
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddTransaction) {
            AddEditTransactionView()
        }
    }

    // MARK: - Hero card

    private var heroCard: some View {
        VStack(spacing: 0) {
            // Month selector
            HStack {
                Button { moveMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(.white.opacity(0.15)))
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(spacing: 1) {
                    Text(currentMonth.formatted(.dateTime.month(.wide)))
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(currentMonth.formatted(.dateTime.year()))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Button { moveMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(.white.opacity(0.15)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Balance
            VStack(spacing: 6) {
                Text("Beschikbaar deze maand")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))

                Text(MoneyFormatter.format(netBalance, currencyCode: currencyCode))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .padding(.vertical, 24)

            // Income / Expenses strip
            HStack(spacing: 0) {
                heroStat(
                    icon: "arrow.down.circle.fill",
                    label: "Inkomen",
                    value: totalIncome,
                    color: Color(red: 0.4, green: 1, blue: 0.7)
                )

                Divider()
                    .background(.white.opacity(0.3))
                    .frame(height: 36)

                heroStat(
                    icon: "arrow.up.circle.fill",
                    label: "Uitgaven",
                    value: totalExpenses,
                    color: Color(red: 1, green: 0.5, blue: 0.5)
                )

                if totalSaved > 0 {
                    Divider()
                        .background(.white.opacity(0.3))
                        .frame(height: 36)

                    heroStat(
                        icon: "star.circle.fill",
                        label: "Gespaard",
                        value: totalSaved,
                        color: Color(red: 1, green: 0.85, blue: 0.4)
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.brand,
                            Color(red: 0.18, green: 0.28, blue: 0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: AppTheme.brand.opacity(0.4), radius: 20, y: 8)
    }

    private func heroStat(icon: String, label: String, value: Decimal, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Text(MoneyFormatter.format(value, currencyCode: currencyCode))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Insights row

    private var insightsRow: some View {
        HStack(spacing: 12) {
            insightCard(
                icon: evolutionPositive ? "arrow.up.right" : "arrow.down.right",
                iconColor: evolutionPositive ? .green : .red,
                title: "t.o.v. vorige maand",
                value: (evolutionPositive ? "+" : "") + MoneyFormatter.format(evolutionAmount, currencyCode: currencyCode),
                valueColor: evolutionPositive ? .green : .red
            )

            if let cat = biggestCategory {
                insightCard(
                    icon: cat.icon,
                    iconColor: AppTheme.brand,
                    title: "Grootste categorie",
                    value: cat.name,
                    valueColor: .primary
                )
            } else {
                insightCard(
                    icon: "tag",
                    iconColor: .secondary,
                    title: "Grootste categorie",
                    value: "–",
                    valueColor: .secondary
                )
            }
        }
    }

    private func insightCard(icon: String, iconColor: Color, title: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBg)
        )
    }

    // MARK: - Recent transactions

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recente transacties")
                    .font(.headline)
                Spacer()
                NavigationLink {
                    TransactionsListView(filterMonth: currentMonth)
                } label: {
                    Text("Alles")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.brand)
                }
            }

            if recentTransactions.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "Geen transacties",
                    message: "Voeg een transactie toe voor deze maand"
                )
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 2) {
                    ForEach(recentTransactions) { tx in
                        NavigationLink {
                            TransactionDetailView(transaction: tx)
                        } label: {
                            TransactionRowView(transaction: tx, currencyCode: currencyCode)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)

                        if tx.id != recentTransactions.last?.id {
                            Divider().padding(.leading, 54)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.cardBg)
                )
            }
        }
    }

    // MARK: - Helpers

    private func moveMonth(by value: Int) {
        let cal = Calendar.current
        let base = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth)) ?? currentMonth
        if let next = cal.date(byAdding: .month, value: value, to: base) {
            withAnimation(.snappy) { currentMonth = next }
        }
    }
}
