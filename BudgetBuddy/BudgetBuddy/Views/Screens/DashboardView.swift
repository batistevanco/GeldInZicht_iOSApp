// /Views/Screens/DashboardView.swift

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.selectedTab) private var selectedTab

    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query(sort: \Account.name) private var allAccounts: [Account]
    @Query(sort: \SavingGoal.name) private var allGoals: [SavingGoal]
    @Query private var settings: [AppSettings]

    @State private var currentMonth: Date = Date()
    @State private var showAddTransaction = false

    private var currencyCode: String { settings.first?.currencyCode ?? "EUR" }

    // MARK: - Computed

    private var monthTransactions: [Transaction] {
        allTransactions.filter {
            Calendar.current.isDate($0.date, equalTo: currentMonth, toGranularity: .month)
            && !$0.isRecurringTemplate
        }
    }

    private var totalIncome: Double {
        monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    private var totalExpenses: Double {
        monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    private var totalSaved: Double {
        monthTransactions.filter { $0.type == .savingDeposit }.reduce(0) { $0 + $1.amount }
    }
    private var netBalance: Double { totalIncome - totalExpenses }

    private var spendingProgress: Double {
        guard totalIncome > 0 else { return 0 }
        let ratio = totalExpenses / totalIncome
        return min(1, max(0, ratio))
    }

    private var activeGoals: [SavingGoal] { allGoals.filter { !$0.isArchived } }
    private var activeAccounts: [Account] { allAccounts.filter { !$0.isArchived } }

    private var biggestExpenseCategory: (name: String, icon: String, amount: Double, colorHex: String?)? {
        let expenses = monthTransactions.filter { $0.type == .expense && $0.category != nil }
        var totals: [UUID: (name: String, icon: String, amount: Double, colorHex: String?)] = [:]
        for tx in expenses {
            guard let cat = tx.category else { continue }
            let cur = totals[cat.id] ?? (cat.name, cat.iconName, 0, cat.colorHex)
            totals[cat.id] = (cur.name, cur.icon, cur.amount + tx.amount, cur.colorHex)
        }
        return totals.values.max(by: { $0.amount < $1.amount })
    }

    private var groupedByDay: [(day: Date, items: [Transaction])] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: monthTransactions) { cal.startOfDay(for: $0.date) }
        return grouped.keys
            .sorted(by: >)
            .prefix(4)
            .map { day in (day: day, items: grouped[day]!.sorted { $0.date > $1.date }) }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // Begroeting + maandkiezer
                    greetingRow
                        .padding(.horizontal)
                        .padding(.top, 4)

                    // Hero card
                    heroCard
                        .padding(.horizontal)

                    // Quick actions
                    quickActions
                        .padding(.horizontal)

                    // Inzicht-rij (grootste categorie + gespaard)
                    if totalIncome > 0 || totalExpenses > 0 {
                        insightRow
                            .padding(.horizontal)
                    }

                    // Spaardoelen preview
                    if !activeGoals.isEmpty {
                        goalsPreview
                            .padding(.horizontal)
                    }

                    // Recente transacties
                    transactionFeed
                        .padding(.horizontal)

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
            ToolbarItem(placement: .principal) {
                HStack(spacing: 0) {
                    Button { moveMonth(by: -1) } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                    }

                    Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(minWidth: 130)
                        .multilineTextAlignment(.center)

                    Button { moveMonth(by: 1) } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                    }
                }
                .background(
                    Capsule()
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
        .sheet(isPresented: $showAddTransaction) {
            AddEditTransactionView()
        }
    }

    // MARK: - Begroeting

    private var greetingRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText)
                    .font(.system(size: 22, weight: .bold))
                Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Goedemorgen 👋"
        case 12..<18: return "Goedemiddag 👋"
        default:      return "Goedenavond 👋"
        }
    }

    // MARK: - Hero card

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Netto saldo
            VStack(alignment: .leading, spacing: 4) {
                Text("Netto deze maand")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))

                Text(MoneyFormatter.format(netBalance, currencyCode: currencyCode))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .padding(24)
            .padding(.bottom, 4)

            // Spending progress bar
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: spendingProgress > 0.85
                                        ? [Color(red: 1, green: 0.45, blue: 0.45), Color(red: 1, green: 0.3, blue: 0.3)]
                                        : [Color(red: 0.4, green: 0.9, blue: 0.65), Color(red: 0.3, green: 0.8, blue: 0.55)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(6, geo.size.width * spendingProgress), height: 6)
                            .animation(.spring(duration: 0.6), value: spendingProgress)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text(String(format: "%.0f%% van inkomen uitgegeven", spendingProgress * 100))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)

            // Inkomsten / Uitgaven / Gespaard
            HStack(spacing: 0) {
                heroStat(label: "Inkomsten",
                         value: MoneyFormatter.format(totalIncome, currencyCode: currencyCode),
                         color: Color(red: 0.4, green: 0.9, blue: 0.65))

                Rectangle().fill(Color.white.opacity(0.12)).frame(width: 1, height: 32)

                heroStat(label: "Uitgaven",
                         value: MoneyFormatter.format(totalExpenses, currencyCode: currencyCode),
                         color: Color(red: 1, green: 0.45, blue: 0.45))

                if totalSaved > 0 {
                    Rectangle().fill(Color.white.opacity(0.12)).frame(width: 1, height: 32)
                    heroStat(label: "Gespaard",
                             value: MoneyFormatter.format(totalSaved, currencyCode: currencyCode),
                             color: Color(red: 1, green: 0.85, blue: 0.4))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black)
        )
    }

    private func heroStat(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .minimumScaleFactor(0.65)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }

    // MARK: - Quick actions

    private var quickActions: some View {
        HStack(spacing: 10) {
            quickActionBtn(icon: "arrow.down", label: "Inkomst", color: Color(red: 0.4, green: 0.9, blue: 0.65)) {
                showAddTransaction = true
            }
            quickActionBtn(icon: "arrow.up", label: "Uitgave", color: Color(red: 1, green: 0.45, blue: 0.45)) {
                showAddTransaction = true
            }
            quickActionBtn(icon: "arrow.left.arrow.right", label: "Transfer", color: Color(white: 0.6)) {
                showAddTransaction = true
            }
            quickActionBtn(icon: "star.fill", label: "Sparen", color: Color(red: 1, green: 0.85, blue: 0.4)) {
                showAddTransaction = true
            }
        }
    }

    private func quickActionBtn(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(color)
                }
                .frame(height: 52)
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Inzicht-rij

    private var insightRow: some View {
        HStack(spacing: 10) {
            // Grootste categorie
            if let cat = biggestExpenseCategory {
                let color = AppTheme.color(from: cat.colorHex) ?? Color(white: 0.25)
                insightCard(
                    icon: cat.icon,
                    iconColor: color,
                    title: "Grootste uitgave",
                    value: cat.name,
                    sub: MoneyFormatter.format(cat.amount, currencyCode: currencyCode)
                )
            }

            // Saldo t.o.v. vorige maand
            let prevNet = previousMonthNet
            let diff = netBalance - prevNet
            insightCard(
                icon: diff >= 0 ? "arrow.up.right" : "arrow.down.right",
                iconColor: diff >= 0 ? Color(red: 0.4, green: 0.9, blue: 0.65) : Color(red: 1, green: 0.45, blue: 0.45),
                title: "vs vorige maand",
                value: (diff >= 0 ? "+" : "") + MoneyFormatter.format(diff, currencyCode: currencyCode),
                sub: nil
            )
        }
    }

    private var previousMonthNet: Double {
        let cal = Calendar.current
        guard let prev = cal.date(byAdding: .month, value: -1, to: currentMonth) else { return 0 }
        let txs = allTransactions.filter {
            cal.isDate($0.date, equalTo: prev, toGranularity: .month) && !$0.isRecurringTemplate
        }
        return txs.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
             - txs.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private func insightCard(icon: String, iconColor: Color, title: String, value: String, sub: String?) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                if let sub {
                    Text(sub)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Spaardoelen preview

    private var goalsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Spaardoelen")
                    .font(.title3.bold())
                Spacer()
                Button { selectedTab.wrappedValue = 2 } label: {
                    Text("Bekijk alles")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color(.secondarySystemBackground)))
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(activeGoals.prefix(4)) { goal in
                        NavigationLink { SavingGoalDetailView(goal: goal) } label: {
                            goalChip(goal)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func goalChip(_ goal: SavingGoal) -> some View {
        let color = AppTheme.color(from: goal.colorHex) ?? Color(white: 0.25)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle().fill(color.opacity(0.15))
                    Image(systemName: goal.effectiveIcon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(color)
                }
                .frame(width: 32, height: 32)
                Spacer()
                if goal.progress >= 1 {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Text(goal.name)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(.primary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(color.opacity(0.12)).frame(height: 4)
                    RoundedRectangle(cornerRadius: 3).fill(color)
                        .frame(width: geo.size.width * goal.progress, height: 4)
                }
            }
            .frame(height: 4)

            Text(String(format: "%.0f%%", goal.progress * 100))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(width: 140)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Transaction feed

    private var transactionFeed: some View {
        VStack(spacing: 22) {
            HStack(alignment: .firstTextBaseline) {
                Text("Recent")
                    .font(.title3.bold())
                Spacer()
                Button { selectedTab.wrappedValue = 1 } label: {
                    Text("Alles")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color(.secondarySystemBackground)))
                }
            }

            if groupedByDay.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(Color(.tertiaryLabel))
                    Text("Geen transacties voor \(currentMonth.formatted(.dateTime.month(.wide)))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 20) {
                    ForEach(groupedByDay, id: \.day) { group in
                        dayGroup(day: group.day, items: group.items)
                    }
                }
            }
        }
    }

    private func dayGroup(day: Date, items: [Transaction]) -> some View {
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

            Text(txAmount(tx))
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
        case .income:           return tx.destinationAccount?.name
        case .expense:          return tx.category?.name
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

    private func txAmount(_ tx: Transaction) -> String {
        switch tx.type {
        case .income:  return "+" + MoneyFormatter.format(tx.amount, currencyCode: currencyCode)
        case .expense: return "-" + MoneyFormatter.format(tx.amount, currencyCode: currencyCode)
        default:       return MoneyFormatter.format(tx.amount, currencyCode: currencyCode)
        }
    }

    private func amountColor(for tx: Transaction) -> Color {
        switch tx.type {
        case .income:  return Color(red: 0.4, green: 0.9, blue: 0.65)
        case .expense: return .primary
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
