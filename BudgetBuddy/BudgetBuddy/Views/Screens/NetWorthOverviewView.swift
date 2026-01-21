//
//  NetWorthOverviewView.swift
//  BudgetBuddy
//
//  Created by Batiste Vancoillie on 20/01/2026.
//


// /Views/Screens/NetWorthOverviewView.swift

import SwiftUI
import SwiftData

struct NetWorthOverviewView: View {
    @Query(sort: \Account.name) private var accounts: [Account]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var settings: [AppSettings]

    private var currencyCode: String { settings.first?.currencyCode ?? "EUR" }

    private var activeAccounts: [Account] { accounts.filter { !$0.isArchived } }

    private var total: Decimal {
        FinanceEngine.netWorth(
            accounts: activeAccounts,
            transactions: transactions
        )
    }

    // MARK: - Projectie volgende maand

    private var currentMonthNet: Decimal {
        let now = Date()
        let totals = FinanceEngine.totals(
            for: transactions,
            period: .month,
            referenceDate: now
        )
        return totals.income - totals.expense
    }

    private var projectedNetWorth: Decimal {
        total + currentMonthNet
    }

    private var slices: [DonutSlice] {
        let colors: [Color] = [.purple, .mint, .blue, .orange, .pink, .teal, .indigo, .yellow]

        return activeAccounts.enumerated().map { idx, acc in
            let balance = FinanceEngine.accountBalance(acc, transactions: transactions)

            return DonutSlice(
                label: acc.name,
                value: max(0, NSDecimalNumber(decimal: balance).doubleValue),
                color: colors[idx % colors.count]
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 10) {

                    VStack(spacing: 6) {
                        Text("Huidig vermogen")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(MoneyFormatter.format(total, currencyCode: currencyCode))
                            .font(.system(size: 34, weight: .bold))
                    }

                    VStack(spacing: 4) {
                        Text("Geschat vermogen volgende maand")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(MoneyFormatter.format(projectedNetWorth, currencyCode: currencyCode))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(currentMonthNet >= 0 ? .green : .red)

                        Text("Gebaseerd op het huidige maandsaldo")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 10)

                DonutChartView(slices: slices)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(activeAccounts) { acc in
                        NavigationLink {
                            AccountDetailView(account: acc)
                        } label: {
                            AccountCardView(account: acc, currencyCode: currencyCode)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // zorgt dat balances consistent zijn na wijzigingen
            let ctx = PersistenceController.makeContainer().mainContext
            _ = ctx
            // (opzettelijk geen save hier; recalc gebeurt bij app launch en na recurring)
        }
    }
}
