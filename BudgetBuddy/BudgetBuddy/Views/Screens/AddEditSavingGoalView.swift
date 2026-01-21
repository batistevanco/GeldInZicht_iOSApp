//
//  AddEditSavingGoalView.swift
//  BudgetBuddy
//
//  Created by Batiste Vancoillie on 20/01/2026.
//


import SwiftUI
import SwiftData

struct AddEditSavingGoalView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var goalAmount: Decimal = 0

    var body: some View {
        NavigationStack {
            Form {
                Section(header: FormSectionHeader(title: "Spaarpot")) {
                    TextField("Naam", text: $name)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Doelbedrag")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("Bijv. 2.500,00", value: $goalAmount, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Nieuw spaarpotje")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Opslaan") {
                        context.insert(SavingGoal(name: name, goalAmount: goalAmount))
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
