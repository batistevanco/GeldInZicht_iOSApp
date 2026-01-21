import SwiftUI
import SwiftData

struct SavingGoalsOverviewView: View {
    @Environment(\.modelContext) private var context
    @Query private var goals: [SavingGoal]
    @State private var showAdd = false

    var body: some View {
        List {
            if goals.isEmpty {
                EmptyStateView(
                    icon: "banknote",
                    title: "Geen spaarpotjes",
                    message: "Maak je eerste spaarpotje aan"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowSeparator(.hidden)
            } else {
                ForEach(goals) { goal in
                    NavigationLink {
                        SavingGoalDetailView(goal: goal)
                    } label: {
                        SavingGoalCardView(goal: goal, currencyCode: "EUR")
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteGoals)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Spaarpotjes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddEditSavingGoalView()
        }
    }

    // MARK: - Delete

    private func deleteGoals(at offsets: IndexSet) {
        for index in offsets {
            let goal = goals[index]
            context.delete(goal)
        }
    }
}
