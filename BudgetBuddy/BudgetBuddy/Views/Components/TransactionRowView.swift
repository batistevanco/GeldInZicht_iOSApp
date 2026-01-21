// /Views/Components/TransactionRowView.swift

import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    var currencyCode: String = "EUR"   // default zodat bestaande calls blijven werken

    private var amountColor: Color {
        switch transaction.type {
        case .income: return .green
        case .expense: return .red
        case .transfer, .savingDeposit, .savingWithdrawal: return .primary
        }
    }

    private var title: String {
        switch transaction.type {
        case .income, .expense:
            return transaction.category?.name ?? transaction.type.uiTitle
        case .transfer:
            return "Overboeking"
        case .savingDeposit:
            return "Storting spaarpot"
        case .savingWithdrawal:
            return "Opname spaarpot"
        }
    }

    private var subtitle: String {
        var parts: [String] = []
        if let d = transaction.descriptionText, !d.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append(d)
        }
        switch transaction.type {
        case .income:
            if let to = transaction.destinationAccount?.name { parts.append("→ \(to)") }
        case .expense:
            if let from = transaction.sourceAccount?.name { parts.append("van \(from)") }
        case .transfer:
            let from = transaction.sourceAccount?.name ?? "?"
            let to = transaction.destinationAccount?.name ?? "?"
            parts.append("\(from) → \(to)")
        case .savingDeposit:
            let from = transaction.sourceAccount?.name ?? "?"
            let goal = transaction.savingGoal?.name ?? "?"
            parts.append("\(from) → \(goal)")
        case .savingWithdrawal:
            let goal = transaction.savingGoal?.name ?? "?"
            let to = transaction.destinationAccount?.name ?? "?"
            parts.append("\(goal) → \(to)")
        }
        return parts.joined(separator: " · ")
    }

    private var iconName: String {
        if let cat = transaction.category?.iconName, (transaction.type == .income || transaction.type == .expense) {
            return cat
        }
        switch transaction.type {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        case .savingDeposit: return "tray.and.arrow.down.fill"
        case .savingWithdrawal: return "tray.and.arrow.up.fill"
        }
    }

    private var iconBg: Color {
        if let c = AppTheme.color(from: transaction.category?.colorHex), (transaction.type == .income || transaction.type == .expense) {
            return c.opacity(0.25)
        }
        return AppTheme.brand.opacity(0.18)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(iconBg)
                Image(systemName: iconName)
                    .foregroundStyle(AppTheme.brand)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title).font(.headline)
                    if transaction.isRecurringTemplate {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(MoneyFormatter.format(transaction.amountSignedForUI, currencyCode: currencyCode))
                .font(.headline)
                .foregroundStyle(amountColor)
        }
        .padding(.vertical, 6)
    }
}

private extension Transaction {
    var amountSignedForUI: Decimal {
        switch type {
        case .income: return amount
        case .expense: return -amount
        case .transfer, .savingDeposit, .savingWithdrawal: return amount
        }
    }
}
