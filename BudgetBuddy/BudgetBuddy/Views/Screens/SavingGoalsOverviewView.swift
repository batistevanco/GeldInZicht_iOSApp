// /Views/Screens/SavingGoalsOverviewView.swift

import SwiftUI
import SwiftData

struct SavingGoalsOverviewView: View {
    @Environment(\.modelContext) private var context
    @Query private var goals: [SavingGoal]
    @Query private var settings: [AppSettings]
    @State private var showAdd = false

    private var currencyCode: String { settings.first?.currencyCode ?? "EUR" }
    private var activeGoals: [SavingGoal] { goals.filter { !$0.isArchived } }
    private var completedGoals: [SavingGoal] { goals.filter { !$0.isArchived && $0.progress >= 1 } }

    private var totalSaved: Double { activeGoals.reduce(0) { $0 + $1.currentAmount } }
    private var totalTarget: Double { activeGoals.reduce(0) { $0 + $1.goalAmount } }
    private var overallProgress: Double {
        guard totalTarget > 0 else { return 0 }
        return min(1, totalSaved / totalTarget)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !activeGoals.isEmpty {
                    heroCard
                        .padding(.horizontal)
                }

                if activeGoals.isEmpty {
                    EmptyStateView(
                        icon: "star.circle",
                        title: "Geen spaardoelen",
                        message: "Maak je eerste spaardoel aan"
                    )
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(activeGoals) { goal in
                            NavigationLink {
                                SavingGoalDetailView(goal: goal)
                            } label: {
                                GoalGridCard(goal: goal, currencyCode: currencyCode)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

                Color.clear.frame(height: 20)
            }
            .padding(.top, 16)
        }
        .background(AppTheme.softBg)
        .navigationTitle("Spaardoelen")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAdd) { AddEditSavingGoalView() }
    }

    // MARK: - Hero card

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Totaal gespaard")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                    Text(MoneyFormatter.format(totalSaved, currencyCode: currencyCode))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Doel")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                    Text(MoneyFormatter.format(totalTarget, currencyCode: currencyCode))
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }

            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.white.opacity(0.2))
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.white)
                            .frame(width: geo.size.width * overallProgress, height: 10)
                    }
                }
                .frame(height: 10)

                HStack {
                    Text(String(format: "%.0f%% bereikt", overallProgress * 100))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                    Spacer()
                    Text("\(completedGoals.count) van \(activeGoals.count) voltooid")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    colors: [Color(red: 0.55, green: 0.35, blue: 0.98), Color(red: 0.35, green: 0.55, blue: 0.98)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .shadow(color: .purple.opacity(0.3), radius: 14, y: 6)
    }
}

// MARK: - GoalGridCard

private struct GoalGridCard: View {
    let goal: SavingGoal
    let currencyCode: String

    private var accentColor: Color {
        AppTheme.color(from: goal.colorHex) ?? AppTheme.brand
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle().fill(accentColor.opacity(0.15))
                    Image(systemName: goal.effectiveIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
                .frame(width: 40, height: 40)
                Spacer()
                if goal.progress >= 1 {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(goal.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(MoneyFormatter.format(goal.currentAmount, currencyCode: currencyCode))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
            }

            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(accentColor.opacity(0.15))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(accentColor)
                            .frame(width: geo.size.width * goal.progress, height: 6)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text(String(format: "%.0f%%", goal.progress * 100))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(MoneyFormatter.format(goal.goalAmount, currencyCode: currencyCode))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(AppTheme.cardBg))
    }
}
