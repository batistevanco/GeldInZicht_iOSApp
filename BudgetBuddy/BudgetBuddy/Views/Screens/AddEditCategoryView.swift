//
//  AddEditCategoryView.swift
//  BudgetBuddy
//
//  Created by Batiste Vancoillie on 20/01/2026.
//

import SwiftUI
import SwiftData

struct AddEditCategoryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let category: Category?

    @State private var name: String = ""
    @State private var selectedIcon: String = "tag"

    // Simple, safe SF Symbols set for categories
    private let availableIcons: [String] = [
        "house", "cart", "car", "creditcard", "gamecontroller",
        "briefcase", "fork.knife", "film", "airplane",
        "heart", "gift", "music.note", "pawprint",
        "bolt", "wifi", "phone", "scissors",
        "figure.walk", "figure.run", "bed.double",
        "tag"
    ]

    var body: some View {
        Form {

            // MARK: - Name
            Section(header: Text("Naam")) {
                TextField("Bijv. Boodschappen", text: $name)
            }

            // MARK: - Icon picker
            Section(header: Text("Icoon")) {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 5),
                    spacing: 16
                ) {
                    ForEach(availableIcons, id: \.self) { icon in
                        iconCell(icon)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(category == nil ? "Nieuwe categorie" : "Categorie bewerken")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Opslaan") {
                    save()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("Annuleren") {
                    dismiss()
                }
            }
        }
        .onAppear {
            if let category {
                name = category.name
                selectedIcon = category.iconName
            }
        }
    }

    // MARK: - Icon cell

    private func iconCell(_ icon: String) -> some View {
        ZStack {
            Circle()
                .fill(icon == selectedIcon ? Color.accentColor : Color(uiColor: .secondarySystemBackground))
                .frame(width: 44, height: 44)

            Image(systemName: icon)
                .foregroundColor(icon == selectedIcon ? .white : .primary)
                .font(.system(size: 18, weight: .semibold))
        }
        .onTapGesture {
            selectedIcon = icon
        }
        .accessibilityLabel(icon)
    }

    // MARK: - Save

    private func save() {
        if let category {
            category.name = name
            category.iconName = selectedIcon
        } else {
            let newCategory = Category(
                name: name,
                iconName: selectedIcon,
                isDefault: false
            )
            context.insert(newCategory)
        }

        dismiss()
    }
}
