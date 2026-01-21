import SwiftUI
import SwiftData

struct CategoriesManagementView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \Category.name) private var categories: [Category]

    @State private var showAddCategory = false

    private var defaultCategories: [Category] {
        categories.filter { $0.isDefault }
    }

    private var customCategories: [Category] {
        categories.filter { !$0.isDefault }
    }

    var body: some View {
        List {

            // 📦 DEFAULT CATEGORIES (READ ONLY)
            if !defaultCategories.isEmpty {
                Section("Standaard categorieën") {
                    ForEach(defaultCategories) { category in
                        categoryRow(category)
                    }
                }
            }

            // ✏️ CUSTOM CATEGORIES (EDITABLE)
            Section("Mijn categorieën") {
                if customCategories.isEmpty {
                    Text("Je hebt nog geen eigen categorieën")
                        .foregroundColor(.secondary)
                }

                ForEach(customCategories) { category in
                    NavigationLink {
                        AddEditCategoryView(category: category)
                    } label: {
                        categoryRow(category)
                    }
                }
                .onDelete(perform: deleteCategory)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Categorieën")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddCategory = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddCategory) {
            NavigationStack {
                AddEditCategoryView(category: nil)
            }
        }
    }

    // MARK: - Row

    private func categoryRow(_ category: Category) -> some View {
        HStack(spacing: 12) {
            Image(systemName: category.iconName)
                .frame(width: 24)

            Text(category.name)

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Delete

    private func deleteCategory(at offsets: IndexSet) {
        for index in offsets {
            let category = customCategories[index]
            context.delete(category)
        }
    }
}
