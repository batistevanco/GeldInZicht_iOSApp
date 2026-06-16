import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    let transaction: Transaction

    @Query private var settings: [AppSettings]
    @State private var showEdit = false

    private var currencyCode: String { settings.first?.currencyCode ?? "EUR" }

    private var accentColor: Color {
        if let color = AppTheme.color(from: transaction.category?.colorHex),
           transaction.type == .income || transaction.type == .expense {
            return color
        }

        switch transaction.type {
        case .income: return .green
        case .expense: return .red
        case .transfer: return AppTheme.brand
        case .savingDeposit, .savingWithdrawal: return .orange
        }
    }

    private var amountColor: Color {
        switch transaction.type {
        case .income: return .green
        case .expense: return .red
        case .transfer, .savingDeposit, .savingWithdrawal: return .primary
        }
    }

    private var signedAmount: Double {
        switch transaction.type {
        case .income: return transaction.amount
        case .expense: return -transaction.amount
        case .transfer, .savingDeposit, .savingWithdrawal: return transaction.amount
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

    private var iconName: String {
        if let icon = transaction.category?.iconName,
           transaction.type == .income || transaction.type == .expense {
            return icon
        }

        switch transaction.type {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        case .savingDeposit: return "tray.and.arrow.down.fill"
        case .savingWithdrawal: return "tray.and.arrow.up.fill"
        }
    }

    private var descriptionText: String {
        let trimmed = transaction.descriptionText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Geen omschrijving" : trimmed
    }

    private var dateText: String {
        transaction.date.formatted(date: .long, time: .omitted)
    }

    private var routeText: String {
        switch transaction.type {
        case .income:
            return transaction.destinationAccount?.name ?? "Geen rekening"
        case .expense:
            return transaction.sourceAccount?.name ?? "Geen rekening"
        case .transfer:
            return "\(transaction.sourceAccount?.name ?? "?") -> \(transaction.destinationAccount?.name ?? "?")"
        case .savingDeposit:
            return "\(transaction.sourceAccount?.name ?? "?") -> \(transaction.savingGoal?.name ?? "?")"
        case .savingWithdrawal:
            return "\(transaction.savingGoal?.name ?? "?") -> \(transaction.destinationAccount?.name ?? "?")"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header
                receipt
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 36)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Bonnetje")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEdit = true
                } label: {
                    Label("Bewerken", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            NavigationStack {
                AddEditTransactionView(transaction: transaction)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.16))
                    .frame(width: 74, height: 74)

                Image(systemName: iconName)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(accentColor)
            }

            VStack(spacing: 5) {
                Text(title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(descriptionText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            Text(MoneyFormatter.format(signedAmount, currencyCode: currencyCode))
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(amountColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
    }

    private var receipt: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("BUDGETBUDDY")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .tracking(2)

                Text("Transactiebewijs")
                    .font(.headline.weight(.semibold))
            }
            .padding(.top, 30)
            .padding(.bottom, 22)

            dashedSeparator

            VStack(spacing: 0) {
                receiptRow("Type", transaction.type.uiTitle)
                receiptRow("Datum", dateText)
                receiptRow(routeTitle, routeText)
                receiptRow("Frequentie", transaction.frequency.uiLabel)

                if transaction.isRecurringTemplate {
                    receiptRow("Status", "Terugkerend sjabloon")
                }
            }
            .padding(.vertical, 12)

            dashedSeparator

            VStack(spacing: 12) {
                HStack {
                    Text("TOTAAL")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .tracking(1.4)

                    Spacer()

                    Text(MoneyFormatter.format(signedAmount, currencyCode: currencyCode))
                        .font(.title3.weight(.black))
                        .foregroundStyle(amountColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Text("ID \(transaction.id.uuidString.prefix(8).uppercased())")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 26)
            .padding(.top, 20)
            .padding(.bottom, 30)
        }
        .background {
            ReceiptPaperShape()
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.10), radius: 22, x: 0, y: 12)
        }
        .overlay {
            ReceiptPaperShape()
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        }
    }

    private var routeTitle: String {
        switch transaction.type {
        case .income: return "Naar"
        case .expense: return "Van"
        case .transfer, .savingDeposit, .savingWithdrawal: return "Route"
        }
    }

    private var dashedSeparator: some View {
        Line()
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 6], dashPhase: 0))
            .foregroundStyle(Color.black.opacity(0.16))
            .frame(height: 1)
            .padding(.horizontal, 26)
    }

    private func receiptRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 10)
    }
}

private struct ReceiptPaperShape: Shape {
    func path(in rect: CGRect) -> Path {
        let tooth: CGFloat = 12
        let inset: CGFloat = 6
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY + inset))

        var x = rect.minX
        while x < rect.maxX {
            path.addLine(to: CGPoint(x: min(x + tooth / 2, rect.maxX), y: rect.minY))
            path.addLine(to: CGPoint(x: min(x + tooth, rect.maxX), y: rect.minY + inset))
            x += tooth
        }

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - inset))

        x = rect.maxX
        while x > rect.minX {
            path.addLine(to: CGPoint(x: max(x - tooth / 2, rect.minX), y: rect.maxY))
            path.addLine(to: CGPoint(x: max(x - tooth, rect.minX), y: rect.maxY - inset))
            x -= tooth
        }

        path.closeSubpath()
        return path
    }
}

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
