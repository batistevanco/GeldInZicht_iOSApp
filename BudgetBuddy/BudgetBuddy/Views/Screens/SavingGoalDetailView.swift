// /Views/Screens/SavingGoalDetailView.swift

import SwiftUI
import SwiftData

struct SavingGoalDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let goal: SavingGoal

    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query private var settings: [AppSettings]

    @State private var showDeleteConfirm = false
    @State private var showDeposit = false
    @State private var showWithdrawal = false

    private var currencyCode: String { settings.first?.currencyCode ?? "EUR" }

    private var goalTransactions: [Transaction] {
        allTransactions.filter { $0.savingGoal?.id == goal.id }
    }

    private var accentColor: Color {
        AppTheme.color(from: goal.colorHex) ?? AppTheme.brand
    }

    private var remaining: Double { max(0, goal.goalAmount - goal.currentAmount) }
    private var isCompleted: Bool { goal.progress >= 1 }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroSection
                    .padding(.horizontal)

                actionButtons
                    .padding(.horizontal)

                if !goalTransactions.isEmpty {
                    transactionsSection
                        .padding(.horizontal)
                }

                Color.clear.frame(height: 20)
            }
            .padding(.top, 16)
        }
        .background(AppTheme.softBg)
        .navigationTitle(goal.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) { showDeleteConfirm = true } label: {
                    Image(systemName: "trash").foregroundStyle(.red)
                }
            }
        }
        .alert("Spaardoel verwijderen?", isPresented: $showDeleteConfirm) {
            Button("Verwijderen", role: .destructive) {
                context.delete(goal)
                try? context.save()
                dismiss()
            }
            Button("Annuleren", role: .cancel) { }
        } message: {
            Text("Dit spaardoel en alle bijhorende transacties worden definitief verwijderd.")
        }
        .sheet(isPresented: $showDeposit) {
            AddEditTransactionView(preset: .savingDeposit(goal: goal))
        }
        .sheet(isPresented: $showWithdrawal) {
            AddEditTransactionView(preset: .savingWithdrawal(goal: goal))
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            // Icon + completed badge
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle().fill(accentColor.opacity(0.15))
                    Image(systemName: goal.effectiveIcon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
                .frame(width: 72, height: 72)

                if isCompleted {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                        .background(Circle().fill(Color(.systemBackground)).padding(-2))
                }
            }

            // Amounts
            VStack(spacing: 4) {
                Text(MoneyFormatter.format(goal.currentAmount, currencyCode: currencyCode))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
                Text("van \(MoneyFormatter.format(goal.goalAmount, currencyCode: currencyCode))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Progress bar
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(accentColor.opacity(0.15))
                            .frame(height: 12)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(colors: [accentColor, accentColor.opacity(0.7)],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: geo.size.width * goal.progress, height: 12)
                    }
                }
                .frame(height: 12)

                HStack {
                    Text(String(format: "%.0f%% bereikt", goal.progress * 100))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if !isCompleted {
                        Text("\(MoneyFormatter.format(remaining, currencyCode: currencyCode)) resterend")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Voltooid!")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(AppTheme.cardBg))
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button { showDeposit = true } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Storten")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 14).fill(accentColor))
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            Button { showWithdrawal = true } label: {
                HStack {
                    Image(systemName: "minus.circle.fill")
                    Text("Opnemen")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.tertiarySystemBackground)))
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Transactions

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Transacties")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(Array(goalTransactions.enumerated()), id: \.element.id) { idx, tx in
                    NavigationLink {
                        TransactionDetailView(transaction: tx)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tx.type == .savingDeposit ? "Storting" : "Opname")
                                    .font(.subheadline.weight(.medium))
                                Text(tx.date.formatted(.dateTime.day().month(.wide).year()))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text((tx.type == .savingDeposit ? "+" : "–") + MoneyFormatter.format(tx.amount, currencyCode: currencyCode))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(tx.type == .savingDeposit ? .green : .red)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)

                    if idx < goalTransactions.count - 1 {
                        Divider().padding(.leading, 14)
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.cardBg))
        }
    }
}
