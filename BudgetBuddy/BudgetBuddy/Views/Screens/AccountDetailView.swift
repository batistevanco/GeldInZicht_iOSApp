// /Views/Screens/AccountDetailView.swift

import SwiftUI
import SwiftData

struct AccountDetailView: View {
    let account: Account

    @Environment(\.modelContext) private var context
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query private var settings: [AppSettings]

    @State private var showAddIncome   = false
    @State private var showAddExpense  = false
    @State private var showTransfer    = false
    @State private var showEditAccount = false

    private var currencyCode: String { settings.first?.currencyCode ?? "EUR" }
    private var cardColor: Color { AppTheme.color(from: account.colorHex) ?? AppTheme.brand }

    private var balance: Double {
        FinanceEngine.accountBalance(account, transactions: allTransactions)
    }

    private var cardHolder: String {
        let holder = account.name
            .uppercased()
            .filter { $0.isLetter || $0.isWhitespace }
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return holder.isEmpty ? account.type.uiLabel.uppercased() : holder
    }

    private var cardNumber: String {
        let digits = account.id.uuidString.compactMap { $0.wholeNumberValue }
        let paddedDigits = Array((digits.map(String.init).joined() + "0000000000000000").prefix(16))
        let groups = stride(from: 0, to: paddedDigits.count, by: 4).map { start in
            String(paddedDigits[start..<min(start + 4, paddedDigits.count)])
        }
        return groups.joined(separator: " ")
    }

    private var validThru: String {
        let digits = account.id.uuidString.compactMap { $0.wholeNumberValue }
        let monthSeed = digits.first ?? 1
        let yearSeed = digits.dropFirst().first ?? 0
        let month = (monthSeed % 12) + 1
        let year = 28 + (yearSeed % 6)
        return String(format: "%02d/%02d", month, year)
    }

    private var txs: [Transaction] {
        allTransactions.filter {
            !$0.isRecurringTemplate &&
            ($0.sourceAccount?.id == account.id || $0.destinationAccount?.id == account.id)
        }
    }

    private var groupedByDay: [(day: Date, items: [Transaction])] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: txs) { cal.startOfDay(for: $0.date) }
        return grouped.keys
            .sorted(by: >)
            .map { day in (day: day, items: grouped[day]!.sorted { $0.date > $1.date }) }
    }

    private func setAsDefault() {
        let all = (try? context.fetch(FetchDescriptor<Account>())) ?? []
        all.forEach { $0.isDefault = ($0.id == account.id) }
        try? context.save()
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    heroCard
                    actionButtons
                        .padding(.horizontal)
                        .padding(.top, 24)

                    if groupedByDay.isEmpty {
                        Text("Nog geen transacties voor deze rekening.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 48)
                    } else {
                        VStack(spacing: 20) {
                            ForEach(groupedByDay, id: \.day) { group in
                                daySection(day: group.day, items: group.items)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 28)
                    }

                    Color.clear.frame(height: 40)
                }
            }
        }
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Bewerken") { showEditAccount = true }
            }
        }
        .sheet(isPresented: $showAddIncome)   { AddEditTransactionView(preset: .income(on: account)) }
        .sheet(isPresented: $showAddExpense)  { AddEditTransactionView(preset: .expense(from: account)) }
        .sheet(isPresented: $showTransfer)    { AddEditTransactionView(preset: .transfer(from: account)) }
        .sheet(isPresented: $showEditAccount) { AddEditAccountView(account: account) }
    }

    // MARK: - Hero card

    private var heroCard: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            cardColor.opacity(0.70),
                            cardColor.opacity(0.28),
                            Color.white.opacity(0.22),
                            cardColor.opacity(0.58)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 150, height: 150)
                        .blur(radius: 26)
                        .offset(x: -46, y: 48)
                }
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(cardColor.opacity(0.42))
                        .frame(width: 190, height: 190)
                        .blur(radius: 34)
                        .offset(x: 54, y: -66)
                }

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.14, blue: 0.20),
                            Color(red: 0.17, green: 0.22, blue: 0.30)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 104)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.black.opacity(0.08))
                        .frame(height: 1)
                }

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Text(account.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)

                    Spacer()

                    contactlessMark
                }
                .padding(.top, 24)

                Spacer()

                HStack(alignment: .bottom, spacing: 14) {
                    VStack(alignment: .leading, spacing: 12) {
                        chip

                        Text(MoneyFormatter.format(balance, currencyCode: currencyCode))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.58)
                            .shadow(color: .black.opacity(0.34), radius: 5, y: 2)
                            .shadow(color: .black.opacity(0.18), radius: 1, y: 1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 8) {
                        Text("VISA")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .italic()
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.18), radius: 4, y: 2)

                        Button {
                            if !account.isDefault { setAsDefault() }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: account.isDefault ? "checkmark.seal.fill" : "seal")
                                Text(account.isDefault ? "Standaard" : "Maak standaard")
                            }
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(account.isDefault ? 0.96 : 0.74))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 18)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(cardHolder)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.88))
                            .lineLimit(1)

                        Text(cardNumber)
                            .font(.system(size: 17, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.68)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 7) {
                        Text(validThru)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)

                        Text(account.type.uiLabel.uppercased())
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.58))
                            .lineLimit(1)
                    }
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 22)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 226)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.20), lineWidth: 1)
        }
        .shadow(color: cardColor.opacity(0.26), radius: 24, x: 0, y: 14)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Actieknoppen

    private var actionButtons: some View {
        HStack(spacing: 10) {
            actionBtn(icon: "arrow.down", label: "Storten",    color: cardColor) { showAddIncome  = true }
            actionBtn(icon: "arrow.up",   label: "Opnemen",   color: cardColor) { showAddExpense = true }
            actionBtn(icon: "arrow.left.arrow.right", label: "Overboeken", color: cardColor) { showTransfer = true }
        }
    }

    private func actionBtn(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(white: 0.15))
                }
                .frame(height: 54)

                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var chip: some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.82, blue: 0.48),
                        Color(red: 0.68, green: 0.52, blue: 0.24)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 46, height: 34)
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(Color.black.opacity(0.14), lineWidth: 1)
            }
            .overlay {
                VStack(spacing: 6) {
                    Rectangle().fill(Color.black.opacity(0.12)).frame(height: 1)
                    Rectangle().fill(Color.black.opacity(0.12)).frame(height: 1)
                }
            }
    }

    private var contactlessMark: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .stroke(Color.white.opacity(0.86), lineWidth: 2)
                    .frame(width: CGFloat(6 + index * 5), height: CGFloat(17 + index * 5))
            }
        }
        .frame(width: 34, height: 30)
    }

    // MARK: - Dag-sectie

    private func daySection(day: Date, items: [Transaction]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(dayLabel(for: day))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

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
            return tx.category?.name
        case .expense:
            return tx.category?.name
        case .transfer:
            guard let s = tx.sourceAccount?.name, let d = tx.destinationAccount?.name else { return nil }
            return "\(s) → \(d)"
        case .savingDeposit:
            return tx.savingGoal?.name
        case .savingWithdrawal:
            return tx.savingGoal?.name
        }
    }

    private func txAmountString(_ tx: Transaction) -> String {
        let isInflow = tx.destinationAccount?.id == account.id
        let prefix = isInflow ? "+" : "-"
        return prefix + MoneyFormatter.format(tx.amount, currencyCode: currencyCode)
    }

    private func amountColor(for tx: Transaction) -> Color {
        let isInflow = tx.destinationAccount?.id == account.id
        switch tx.type {
        case .income:           return .green
        case .expense:          return .red
        case .transfer:         return isInflow ? .green : .red
        case .savingDeposit:    return .red
        case .savingWithdrawal: return .green
        }
    }

    private func iconName(for tx: Transaction) -> String {
        if let cat = tx.category?.iconName { return cat }
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
}
