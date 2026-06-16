// /Views/Screens/AccountsOverviewView.swift

import SwiftUI
import SwiftData

struct AccountsOverviewView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Account.name) private var accounts: [Account]
    @Query(sort: \SavingGoal.name) private var goals: [SavingGoal]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var settings: [AppSettings]

    @Environment(\.selectedTab) private var selectedTab
    @State private var showAddAccount = false
    @State private var financeSheet: FinanceSheet?
    @State private var selectedAccountID: UUID?

    private var currencyCode: String { settings.first?.currencyCode ?? "EUR" }
    private var activeAccounts: [Account] { accounts.filter { !$0.isArchived } }
    private var activeGoals: [SavingGoal] { goals.filter { !$0.isArchived } }
    private var primaryAccount: Account? {
        activeAccounts.first(where: { $0.isDefault }) ?? activeAccounts.first
    }
    private var selectedAccount: Account? {
        if let selectedAccountID,
           let account = activeAccounts.first(where: { $0.id == selectedAccountID }) {
            return account
        }

        return primaryAccount
    }
    private var selectedCardColor: Color {
        AppTheme.color(from: selectedAccount?.colorHex) ?? AppTheme.brand
    }

    private var netWorth: Double {
        FinanceEngine.netWorth(accounts: activeAccounts, transactions: transactions)
    }

    private var recentTransactions: [Transaction] {
        Array(transactions.filter { !$0.isRecurringTemplate }.prefix(5))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // Totaal vermogen
                VStack(alignment: .leading, spacing: 4) {
                    Text("Totaal vermogen")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(MoneyFormatter.format(netWorth, currencyCode: currencyCode))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                }
                .padding(.horizontal)
                .padding(.leading, 8)

                // Kaarten en beheer acties
                accountControlSection

                // Spaardoelen
                if !activeGoals.isEmpty {
                    goalsSection
                        .padding(.horizontal)
                }

                // Rekeningen overzicht
                if !activeAccounts.isEmpty {
                    accountsSummarySection
                        .padding(.horizontal)
                }

                // Recente transacties
                if !recentTransactions.isEmpty {
                    recentSection
                        .padding(.horizontal)
                }

                Color.clear.frame(height: 20)
            }
            .padding(.top, 8)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Rekeningen")
        .navigationBarTitleDisplayMode(.large)
        .onAppear(perform: ensureSelectedAccount)
        .onChange(of: activeAccounts.map(\.id)) { _, _ in
            ensureSelectedAccount()
        }
        .sheet(isPresented: $showAddAccount) {
            AddEditAccountView()
        }
        .sheet(item: $financeSheet) { sheet in
            switch sheet {
            case .income(let account):
                AddEditTransactionView(preset: .income(on: account))
            case .transfer(let account):
                AddEditTransactionView(preset: .transfer(from: account))
            }
        }
    }

    // MARK: - Card carousel

    private var accountControlSection: some View {
        VStack(spacing: 0) {
            cardCarousel
            manageFinanceSection
        }
        .background {
            LinearGradient(
                stops: [
                    .init(color: Color(.systemBackground), location: 0.00),
                    .init(color: selectedCardColor.opacity(0.10), location: 0.28),
                    .init(color: Color(.secondarySystemBackground).opacity(0.48), location: 0.72),
                    .init(color: Color(.systemBackground), location: 1.00)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var cardCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {

                // Bestaande rekeningen
                ForEach(Array(activeAccounts.enumerated()), id: \.element.id) { idx, acc in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            selectedAccountID = acc.id
                        }
                    } label: {
                        AccountCard(
                            account: acc,
                            balance: FinanceEngine.accountBalance(acc, transactions: transactions),
                            currencyCode: currencyCode,
                            isSelected: selectedAccount?.id == acc.id
                        )
                    }
                    .buttonStyle(.plain)
                }

                // + Nieuwe rekening
                Button { showAddAccount = true } label: {
                    addCard
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var addCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color(.separator), style: StrokeStyle(lineWidth: 1.5, dash: [7, 5]))
                }

            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(width: 330, height: 206)
    }

    private var manageFinanceSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Beheer financiën")
                        .font(.title3.bold())

                    Text(selectedAccount?.name ?? "Kies een kaart")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                NavigationLink { MoreView() } label: {
                    Text("Alles bekijken")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.brand.opacity(0.72))
                }
            }

            HStack(spacing: 10) {
                financeActionButton(
                    title: "Storten",
                    systemImage: "wallet.pass",
                    isEnabled: selectedAccount != nil
                ) {
                    if let selectedAccount {
                        financeSheet = .income(selectedAccount)
                    }
                }

                if let selectedAccount {
                    NavigationLink { AccountDetailView(account: selectedAccount) } label: {
                        financeActionLabel(title: "Details", systemImage: "creditcard")
                    }
                    .buttonStyle(.plain)
                } else {
                    financeActionButton(title: "Details", systemImage: "creditcard", isEnabled: false) { }
                }

                financeActionButton(
                    title: "Overboeken",
                    systemImage: "arrow.left.arrow.right",
                    isEnabled: selectedAccount != nil
                ) {
                    if let selectedAccount {
                        financeSheet = .transfer(selectedAccount)
                    }
                }

                financeActionButton(title: "Nieuw", systemImage: "plus") {
                    showAddAccount = true
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func ensureSelectedAccount() {
        guard !activeAccounts.isEmpty else {
            selectedAccountID = nil
            return
        }

        if let selectedAccountID,
           activeAccounts.contains(where: { $0.id == selectedAccountID }) {
            return
        }

        selectedAccountID = primaryAccount?.id
    }

    private func financeActionButton(
        title: String,
        systemImage: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            financeActionLabel(title: title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.38)
    }

    private func financeActionLabel(title: String, systemImage: String) -> some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 8)

                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(red: 0.10, green: 0.14, blue: 0.20))
            }
            .frame(width: 54, height: 54)

            Text(title)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Rekeningen overzicht

    private var accountsSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Alle rekeningen")
                    .font(.title3.bold())

                Spacer()

                Text("\(activeAccounts.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                ForEach(activeAccounts) { account in
                    NavigationLink { AccountDetailView(account: account) } label: {
                        accountSummaryRow(account)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)

                    if account.id != activeAccounts.last?.id {
                        Divider().padding(.leading, 70)
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(.secondarySystemBackground)))
        }
    }

    private func accountSummaryRow(_ account: Account) -> some View {
        let color = AppTheme.color(from: account.colorHex) ?? AppTheme.brand
        let balance = FinanceEngine.accountBalance(account, transactions: transactions)

        return HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.16))
                Image(systemName: account.effectiveIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(account.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    if account.isDefault {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(AppTheme.brand)
                    }
                }

                Text(account.type.uiLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            Text(MoneyFormatter.format(balance, currencyCode: currencyCode))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(balance < 0 ? .red : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
    }

    // MARK: - Spaardoelen

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Spaardoelen")
                    .font(.title3.bold())
                Spacer()
                NavigationLink { SavingGoalsOverviewView() } label: {
                    Text("Alles bekijken")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 10) {
                ForEach(activeGoals.prefix(3)) { goal in
                    NavigationLink { SavingGoalDetailView(goal: goal) } label: {
                        goalRow(goal)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func goalRow(_ goal: SavingGoal) -> some View {
        let color = AppTheme.color(from: goal.colorHex) ?? AppTheme.brand
        return HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.12))
                Image(systemName: goal.effectiveIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(goal.name).font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(MoneyFormatter.format(goal.currentAmount, currencyCode: currencyCode))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(color)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(color.opacity(0.12)).frame(height: 5)
                        RoundedRectangle(cornerRadius: 4).fill(color)
                            .frame(width: geo.size.width * goal.progress, height: 5)
                    }
                }
                .frame(height: 5)
                HStack {
                    Text(String(format: "%.0f%%", goal.progress * 100))
                        .font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Text("van " + MoneyFormatter.format(goal.goalAmount, currencyCode: currencyCode))
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemBackground)))
    }

    // MARK: - Recente transacties

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Recente transacties")
                    .font(.title3.bold())
                Spacer()
                Button {
                    selectedTab.wrappedValue = 1
                } label: {
                    Text("Alles bekijken")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 0) {
                ForEach(recentTransactions) { tx in
                    NavigationLink { TransactionDetailView(transaction: tx) } label: {
                        TransactionRowView(transaction: tx, currencyCode: currencyCode)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    if tx.id != recentTransactions.last?.id {
                        Divider().padding(.leading, 70)
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(.secondarySystemBackground)))
        }
    }
}

private enum FinanceSheet: Identifiable {
    case income(Account)
    case transfer(Account)

    var id: String {
        switch self {
        case .income(let account):
            return "income-\(account.id)"
        case .transfer(let account):
            return "transfer-\(account.id)"
        }
    }
}

// MARK: - AccountCard

private struct AccountCard: View {
    let account: Account
    let balance: Double
    let currencyCode: String
    let isSelected: Bool

    private var cardColor: Color {
        AppTheme.color(from: account.colorHex) ?? AppTheme.brand
    }

    private var gradientColors: [Color] {
        [
            cardColor.opacity(0.48),
            cardColor.opacity(0.22),
            Color.white.opacity(0.34),
            cardColor.opacity(0.36)
        ]
    }

    private var darkStripColors: [Color] {
        [
            Color(red: 0.10, green: 0.14, blue: 0.20),
            Color(red: 0.17, green: 0.22, blue: 0.30)
        ]
    }

    private var cardHolder: String {
        account.name
            .uppercased()
            .filter { $0.isLetter || $0.isWhitespace }
            .trimmingCharacters(in: .whitespacesAndNewlines)
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

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 122, height: 122)
                        .blur(radius: 22)
                        .offset(x: -34, y: 48)
                }
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(cardColor.opacity(0.28))
                        .frame(width: 150, height: 150)
                        .blur(radius: 26)
                        .offset(x: 38, y: -58)
                }

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: darkStripColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 92)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.black.opacity(0.08))
                        .frame(height: 1)
                }

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Text(account.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Spacer()

                    contactlessMark
                }
                .padding(.top, 22)

                Spacer()

                HStack(alignment: .bottom, spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        chip

                        Text(MoneyFormatter.format(balance, currencyCode: currencyCode))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                            .shadow(color: .black.opacity(0.34), radius: 5, y: 2)
                            .shadow(color: .black.opacity(0.18), radius: 1, y: 1)
                    }

                    Spacer()

                    Text("VISA")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .italic()
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                }
                .padding(.bottom, 18)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(cardHolder.isEmpty ? account.type.uiLabel.uppercased() : cardHolder)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.88))
                            .lineLimit(1)

                        Text(cardNumber)
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
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
                .padding(.bottom, 18)
            }
            .padding(.horizontal, 20)
        }
        .frame(width: 330, height: 206)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(isSelected ? AppTheme.brand.opacity(0.95) : Color.white.opacity(0.18), lineWidth: isSelected ? 3 : 1)
        }
        .overlay(alignment: .topTrailing) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white, AppTheme.brand)
                    .padding(14)
            }
        }
        .scaleEffect(isSelected ? 1 : 0.97)
        .shadow(color: cardColor.opacity(isSelected ? 0.34 : 0.20), radius: isSelected ? 22 : 14, x: 0, y: isSelected ? 12 : 8)
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
            .frame(width: 44, height: 32)
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
}
