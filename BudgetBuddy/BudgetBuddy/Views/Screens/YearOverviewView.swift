// /Views/Screens/YearOverviewView.swift

import SwiftUI
import SwiftData

struct YearOverviewView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query private var settings: [AppSettings]

    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int? = nil

    private var currencyCode: String { settings.first?.currencyCode ?? "EUR" }

    private var availableYears: [Int] {
        let years = allTransactions.map { Calendar.current.component(.year, from: $0.date) }
        return Array(Set(years)).sorted().reversed()
    }

    private struct MonthData: Identifiable {
        let id = UUID()
        let month: Int
        let label: String
        let income: Decimal
        let expense: Decimal
        var net: Decimal { income - expense }
    }

    private var monthlyData: [MonthData] {
        let cal = Calendar.current
        let yearTx = allTransactions.filter {
            cal.component(.year, from: $0.date) == selectedYear
        }

        return (1...12).map { month in
            let monthTx = yearTx.filter { cal.component(.month, from: $0.date) == month }
            let income = monthTx.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = monthTx.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            let label = cal.shortMonthSymbols[month - 1]
            return MonthData(month: month, label: label, income: income, expense: expense)
        }
    }

    private var annualIncome: Decimal { monthlyData.reduce(0) { $0 + $1.income } }
    private var annualExpense: Decimal { monthlyData.reduce(0) { $0 + $1.expense } }
    private var annualNet: Decimal { annualIncome - annualExpense }

    private var maxValue: Double {
        monthlyData.flatMap { [
            NSDecimalNumber(decimal: $0.income).doubleValue,
            NSDecimalNumber(decimal: $0.expense).doubleValue
        ]}.max() ?? 1
    }

    private var selectedMonthData: MonthData? {
        guard let m = selectedMonth else { return nil }
        return monthlyData.first { $0.month == m }
    }

    private var selectedMonthTransactions: [Transaction] {
        guard let m = selectedMonth else { return [] }
        let cal = Calendar.current
        return allTransactions.filter {
            cal.component(.year, from: $0.date) == selectedYear &&
            cal.component(.month, from: $0.date) == m
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                yearPicker
                    .padding(.horizontal)

                annualSummaryCard
                    .padding(.horizontal)

                chartSection
                    .padding(.horizontal)

                if let data = selectedMonthData {
                    selectedMonthSection(data)
                        .padding(.horizontal)
                }

                Color.clear.frame(height: 20)
            }
            .padding(.top, 16)
        }
        .background(AppTheme.softBg)
        .navigationTitle("Jaaroverzicht")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Year picker

    private var yearPicker: some View {
        HStack {
            Button { if let prev = availableYears.last(where: { $0 < selectedYear }) { selectedYear = prev; selectedMonth = nil } } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(AppTheme.cardBg))
            }
            .buttonStyle(.plain)
            .opacity(availableYears.contains(where: { $0 < selectedYear }) ? 1 : 0.3)

            Spacer()
            Text(String(selectedYear))
                .font(.title2.bold())
            Spacer()

            Button { if let next = availableYears.first(where: { $0 > selectedYear }) { selectedYear = next; selectedMonth = nil } } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(AppTheme.cardBg))
            }
            .buttonStyle(.plain)
            .opacity(availableYears.contains(where: { $0 > selectedYear }) ? 1 : 0.3)
        }
    }

    // MARK: - Annual summary

    private var annualSummaryCard: some View {
        HStack(spacing: 0) {
            annualStat("Inkomen", value: annualIncome, color: .green)
            Divider().frame(height: 44)
            annualStat("Uitgaven", value: annualExpense, color: .red)
            Divider().frame(height: 44)
            annualStat("Netto", value: annualNet, color: annualNet >= 0 ? AppTheme.brand : .red)
        }
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.cardBg))
    }

    private func annualStat(_ label: String, value: Decimal, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(MoneyFormatter.format(value, currencyCode: currencyCode))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bar chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Maandoverzicht")
                    .font(.headline)
                Spacer()
                HStack(spacing: 12) {
                    legend(color: .green, label: "Inkomen")
                    legend(color: .red, label: "Uitgaven")
                }
            }

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(monthlyData) { data in
                    monthBar(data)
                }
            }
            .frame(height: 140)
            .padding(.bottom, 4)

            if selectedMonth == nil {
                Text("Tik op een maand voor details")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.cardBg))
    }

    private func monthBar(_ data: MonthData) -> some View {
        let isSelected = selectedMonth == data.month
        let incH = maxValue > 0 ? NSDecimalNumber(decimal: data.income).doubleValue / maxValue : 0
        let expH = maxValue > 0 ? NSDecimalNumber(decimal: data.expense).doubleValue / maxValue : 0
        let chartH: Double = 110

        return VStack(spacing: 2) {
            HStack(alignment: .bottom, spacing: 1) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(isSelected ? Color.green : Color.green.opacity(0.6))
                    .frame(width: 6, height: max(3, incH * chartH))

                RoundedRectangle(cornerRadius: 3)
                    .fill(isSelected ? Color.red : Color.red.opacity(0.6))
                    .frame(width: 6, height: max(3, expH * chartH))
            }

            Text(data.label)
                .font(.system(size: 8, weight: isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? AppTheme.brand : .secondary)
        }
        .frame(maxWidth: .infinity)
        .onTapGesture {
            withAnimation(.snappy) {
                selectedMonth = selectedMonth == data.month ? nil : data.month
            }
        }
        .overlay(
            isSelected ?
                RoundedRectangle(cornerRadius: 6)
                    .stroke(AppTheme.brand, lineWidth: 1.5)
                    .padding(.bottom, -2)
                : nil
        )
    }

    private func legend(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    // MARK: - Selected month detail

    private func selectedMonthSection(_ data: MonthData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(Calendar.current.monthSymbols[data.month - 1] + " \(selectedYear)")
                    .font(.headline)
                Spacer()
                Text((data.net >= 0 ? "+" : "") + MoneyFormatter.format(data.net, currencyCode: currencyCode))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(data.net >= 0 ? .green : .red)
            }

            HStack(spacing: 12) {
                monthStatCard("Inkomen", value: data.income, color: .green)
                monthStatCard("Uitgaven", value: data.expense, color: .red)
            }

            if !selectedMonthTransactions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(selectedMonthTransactions.prefix(8).enumerated()), id: \.element.id) { idx, tx in
                        NavigationLink {
                            TransactionDetailView(transaction: tx)
                        } label: {
                            TransactionRowView(transaction: tx, currencyCode: currencyCode)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        if idx < min(7, selectedMonthTransactions.count - 1) {
                            Divider().padding(.leading, 54)
                        }
                    }
                }
                .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.cardBg))
            }
        }
    }

    private func monthStatCard(_ label: String, value: Decimal, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(MoneyFormatter.format(value, currencyCode: currencyCode))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.cardBg))
    }
}
