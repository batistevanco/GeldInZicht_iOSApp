import SwiftUI
import SwiftData

struct SavingGoalDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let goal: SavingGoal

    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(spacing: 16) {
            Text(goal.name)
                .font(.largeTitle.bold())

            ProgressView(value: goal.progress)

            Text("\(MoneyFormatter.format(goal.currentAmount)) / \(MoneyFormatter.format(goal.goalAmount))")
                .font(.headline)

            Spacer()
        }
        .padding()
        .navigationTitle("Spaarpot")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("Spaarpot verwijderen?", isPresented: $showDeleteConfirm) {
            Button("Verwijderen", role: .destructive) {
                context.delete(goal)
                try? context.save()
                dismiss()
            }
            Button("Annuleren", role: .cancel) { }
        } message: {
            Text("Deze spaarpot en alle bijhorende transacties worden definitief verwijderd.")
        }
    }
}
