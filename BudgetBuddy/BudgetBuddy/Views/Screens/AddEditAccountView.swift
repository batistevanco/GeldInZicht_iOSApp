import SwiftUI
import SwiftData

// /Views/Screens/AddEditAccountView.swift

struct AddEditAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    // When nil → new account, otherwise edit
    let account: Account?

    @State private var name: String = ""
    @State private var type: AccountType = .checking
    @State private var initial: Decimal = 0
    @State private var iconName: String = "creditcard.fill"
    @State private var colorHex: String = "#3B82F6" // default blue

    // Preset brand-friendly colors
    private let colorOptions: [String] = [
        "#3B82F6", // blue
        "#22C55E", // green
        "#EF4444", // red
        "#F59E0B", // orange
        "#8B5CF6", // purple
        "#06B6D4", // cyan
        "#64748B"  // gray
    ]

    init(account: Account? = nil) {
        self.account = account
    }

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Account info
                Section(header: FormSectionHeader(title: "Rekening")) {
                    TextField("Naam", text: $name)

                    Picker("Type", selection: $type) {
                        ForEach(AccountType.allCases) { t in
                            Text(t.uiLabel).tag(t)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Startsaldo")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("Bijv. 1250,00", value: $initial, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }

                // MARK: - Color selector
                Section(header: FormSectionHeader(title: "Kleur")) {
                    HStack(spacing: 14) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(AppTheme.color(from: hex) ?? .blue)
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            hex == colorHex ? Color.primary : .clear,
                                            lineWidth: 3
                                        )
                                )
                                .onTapGesture {
                                    colorHex = hex
                                }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(account == nil ? "Nieuwe rekening" : "Rekening bewerken")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleren") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Opslaan") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                loadIfNeeded()
            }
        }
    }

    // MARK: - Load existing account

    private func loadIfNeeded() {
        guard let account else { return }
        name = account.name
        type = account.type
        initial = account.initialBalance
        iconName = account.iconName ?? iconName
        colorHex = account.colorHex ?? colorHex
    }

    // MARK: - Save

    private func save() {
        if let account {
            // Edit existing
            account.name = name
            account.type = type
            account.initialBalance = initial
            account.iconName = iconName
            account.colorHex = colorHex
        } else {
            // Create new
            let a = Account(name: name, type: type, initialBalance: initial)
            a.iconName = iconName
            a.colorHex = colorHex
            context.insert(a)
        }

        try? context.save()
        dismiss()
    }
}
