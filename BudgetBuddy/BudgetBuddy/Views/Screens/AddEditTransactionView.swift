import SwiftUI
import SwiftData

struct AddEditTransactionView: View {
    enum Preset {
        case none
        case income(on: Account)
        case expense(from: Account)
        case transfer(from: Account)
        case savingDeposit(goal: SavingGoal?)
        case savingWithdrawal(goal: SavingGoal?)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: \Account.name) private var accounts: [Account]
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \SavingGoal.name) private var goals: [SavingGoal]
    @Query private var settings: [AppSettings]

    private let preset: Preset
    private let transactionToEdit: Transaction?

    @State private var mainSegment: Int = 1
    @State private var savingSegment: Int = 0

    @State private var amount: Double = 0
    @State private var date = Date()
    @State private var description = ""

    @State private var frequency: TransactionFrequency = .none
    @State private var isRecurringTemplate = false

    @State private var selectedCategory: Category?
    @State private var sourceAccount: Account?
    @State private var destinationAccount: Account?
    @State private var selectedGoal: SavingGoal?

    @State private var errors: [String] = []
    @State private var showDeleteConfirm = false
    @State private var showErrorAlert = false
    @State private var showCategoryManager = false

    private var currencyCode: String { settings.first?.currencyCode ?? "EUR" }

    init(preset: Preset = .none) {
        self.preset = preset
        self.transactionToEdit = nil
    }

    init(transaction: Transaction) {
        self.preset = .none
        self.transactionToEdit = transaction
    }

    // MARK: - Type colours

    private var accentColor: Color {
        switch mainSegment {
        case 0: return .green
        case 1: return .red
        case 2: return .orange
        default: return AppTheme.brand
        }
    }

    private var typeLabels: [(Int, String)] {
        [(0, "IN"), (1, "UIT"), (2, "SPAREN"), (3, "TRANSFER")]
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Type pills
                        typePills
                            .padding(.horizontal)
                            .padding(.top, 8)

                        // Bedrag card
                        amountCard
                            .padding(.horizontal)

                        // Details card
                        detailsCard
                            .padding(.horizontal)

                        // Type-specifieke velden
                        if mainSegment == 0 { typeCard(content: incomeFields) }
                        if mainSegment == 1 { typeCard(content: expenseFields) }
                        if mainSegment == 2 { typeCard(content: savingFields) }
                        if mainSegment == 3 { typeCard(content: transferFields) }

                        // Delete knop (alleen bij bewerken)
                        if transactionToEdit != nil {
                            Button(role: .destructive) { showDeleteConfirm = true } label: {
                                Label("Transactie verwijderen", systemImage: "trash")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }

                        Color.clear.frame(height: 90)
                    }
                }
                .scrollDismissesKeyboard(.interactively)

                // Opslaan knop
                saveButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
            .navigationTitle(transactionToEdit == nil ? "Nieuwe transactie" : "Bewerken")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleren") { dismiss() }
                        .foregroundStyle(.primary)
                }
            }
            .alert("Kan niet opslaan", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errors.joined(separator: "\n"))
            }
            .confirmationDialog("Transactie verwijderen?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Verwijderen", role: .destructive) {
                    if let tx = transactionToEdit {
                        context.delete(tx)
                        try? context.save()
                        FinanceEngine.recalculateAll(context: context)
                        dismiss()
                    }
                }
                Button("Annuleren", role: .cancel) {}
            } message: {
                Text("Deze transactie wordt definitief verwijderd.")
            }
            .sheet(isPresented: $showCategoryManager) {
                NavigationStack { CategoriesManagementView() }
            }
            .onAppear {
                if let tx = transactionToEdit {
                    load(from: tx)
                    if tx.isRecurringTemplate {
                        isRecurringTemplate = true
                        if tx.frequency == .none { frequency = .monthly }
                    }
                } else {
                    applyPresetIfNeeded()
                    let def = resolveDefaultAccount()
                    switch mainSegment {
                    case 1: sourceAccount = sourceAccount ?? def
                    case 2: if savingSegment == 0 { sourceAccount = sourceAccount ?? def } else { destinationAccount = destinationAccount ?? def }
                    case 3: sourceAccount = sourceAccount ?? def
                    default: break
                    }
                }
            }
        }
    }

    // MARK: - Type pills

    private var typePills: some View {
        HStack(spacing: 8) {
            ForEach(typeLabels, id: \.0) { tag, label in
                Button {
                    withAnimation(.snappy(duration: 0.2)) { mainSegment = tag }
                } label: {
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(
                            Capsule().fill(mainSegment == tag ? Color.black : Color(.secondarySystemGroupedBackground))
                        )
                        .foregroundStyle(mainSegment == tag ? .white : .primary)
                }
                .buttonStyle(.plain)
                .disabled(transactionToEdit != nil)
            }
            Spacer()
        }
    }

    // MARK: - Bedrag card

    private var amountCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("BEDRAG")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .kerning(0.8)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    TextField("0", value: $amount, format: .number)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(currencyCode)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 1)

                Text(MoneyFormatter.format(amount, currencyCode: currencyCode))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
        }
    }

    // MARK: - Details card

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DETAILS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .kerning(0.8)

            VStack(spacing: 0) {
                // Omschrijving
                HStack {
                    TextField("Omschrijving (optioneel)", text: $description)
                        .font(.body)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider().padding(.leading, 16)

                // Datum
                HStack {
                    Text("Datum")
                        .font(.body)
                    Spacer()
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider().padding(.leading, 16)

                // Frequentie
                HStack {
                    Text("Frequentie")
                        .font(.body)
                    Spacer()
                    Picker("", selection: $frequency) {
                        ForEach(TransactionFrequency.allCases) { f in
                            Text(f.uiLabel).tag(f)
                        }
                    }
                    .labelsHidden()
                    .tint(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider().padding(.leading, 16)

                // Terugkerend
                Toggle(isOn: $isRecurringTemplate) {
                    Text("Terugkerende transactie")
                        .font(.body)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
        }
    }

    // MARK: - Type-specifieke velden wrapper

    private func typeCard<C: View>(content: C) -> some View {
        let label: String
        switch mainSegment {
        case 0: label = "INKOMEN"
        case 1: label = "UITGAVE"
        case 2: label = "SPAARPOT"
        default: label = "OVERBOEKING"
        }
        return VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .kerning(0.8)

            content
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
        }
        .padding(.horizontal)
    }

    // MARK: - Inkomsten

    private var incomeFields: some View {
        VStack(spacing: 0) {
            pickerRow(label: "Categorie") {
                Picker("", selection: $selectedCategory) {
                    Text("Kies…").tag(Category?.none)
                    ForEach(categories) { c in Text(c.name).tag(Category?.some(c)) }
                }.labelsHidden()
            }
            Divider().padding(.leading, 16)
            newCategoryButton
            Divider().padding(.leading, 16)
            pickerRow(label: "Rekening (komt bij)") {
                Picker("", selection: $destinationAccount) {
                    Text("Kies…").tag(Account?.none)
                    ForEach(accounts.filter { !$0.isArchived }) { a in Text(a.name).tag(Account?.some(a)) }
                }.labelsHidden()
            }
        }
    }

    // MARK: - Uitgaven

    private var expenseFields: some View {
        VStack(spacing: 0) {
            pickerRow(label: "Categorie") {
                Picker("", selection: $selectedCategory) {
                    Text("Kies…").tag(Category?.none)
                    ForEach(categories) { c in Text(c.name).tag(Category?.some(c)) }
                }.labelsHidden()
            }
            Divider().padding(.leading, 16)
            newCategoryButton
            Divider().padding(.leading, 16)
            pickerRow(label: "Rekening (gaat af)") {
                Picker("", selection: $sourceAccount) {
                    Text("Kies…").tag(Account?.none)
                    ForEach(accounts.filter { !$0.isArchived }) { a in Text(a.name).tag(Account?.some(a)) }
                }.labelsHidden()
            }
        }
    }

    // MARK: - Sparen

    private var savingFields: some View {
        VStack(spacing: 0) {
            // Storten / Opnemen pill
            HStack {
                ForEach([(0, "Storten"), (1, "Opnemen")], id: \.0) { tag, label in
                    Button {
                        withAnimation(.snappy(duration: 0.18)) { savingSegment = tag }
                    } label: {
                        Text(label)
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(savingSegment == tag ? Color.black : Color(.tertiarySystemGroupedBackground)))
                            .foregroundStyle(savingSegment == tag ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)

            Divider().padding(.leading, 16)

            pickerRow(label: "Spaarpot") {
                Picker("", selection: $selectedGoal) {
                    Text("Kies…").tag(SavingGoal?.none)
                    ForEach(goals.filter { !$0.isArchived }) { g in Text(g.name).tag(SavingGoal?.some(g)) }
                }.labelsHidden()
            }

            Divider().padding(.leading, 16)

            if savingSegment == 0 {
                pickerRow(label: "Bronrekening") {
                    Picker("", selection: $sourceAccount) {
                        Text("Kies…").tag(Account?.none)
                        ForEach(accounts.filter { !$0.isArchived }) { a in Text(a.name).tag(Account?.some(a)) }
                    }.labelsHidden()
                }
            } else {
                pickerRow(label: "Bestemmingsrekening") {
                    Picker("", selection: $destinationAccount) {
                        Text("Kies…").tag(Account?.none)
                        ForEach(accounts.filter { !$0.isArchived }) { a in Text(a.name).tag(Account?.some(a)) }
                    }.labelsHidden()
                }
            }
        }
    }

    // MARK: - Transfer

    private var transferFields: some View {
        VStack(spacing: 0) {
            pickerRow(label: "Van") {
                Picker("", selection: $sourceAccount) {
                    Text("Kies…").tag(Account?.none)
                    ForEach(accounts.filter { !$0.isArchived }) { a in Text(a.name).tag(Account?.some(a)) }
                }.labelsHidden()
            }
            Divider().padding(.leading, 16)
            pickerRow(label: "Naar") {
                Picker("", selection: $destinationAccount) {
                    Text("Kies…").tag(Account?.none)
                    ForEach(accounts.filter { !$0.isArchived }) { a in Text(a.name).tag(Account?.some(a)) }
                }.labelsHidden()
            }
        }
    }

    // MARK: - Herbruikbare rijen

    private func pickerRow<P: View>(label: String, @ViewBuilder picker: () -> P) -> some View {
        HStack {
            Text(label).font(.body)
            Spacer()
            picker()
                .tint(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var newCategoryButton: some View {
        Button { showCategoryManager = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.primary)
                Text("Nieuwe categorie")
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Opslaan knop

    private var saveButton: some View {
        Button(action: save) {
            HStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color(white: 0.28))
                        .frame(width: 46, height: 46)
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.leading, 6)

                Text(transactionToEdit == nil ? "Opslaan" : "Wijzigingen opslaan")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.trailing, 52)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(Capsule().fill(Color(red: 0.10, green: 0.12, blue: 0.18)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Logica (ongewijzigd)

    private func load(from tx: Transaction) {
        amount = tx.amount
        date = tx.date
        description = tx.descriptionText ?? ""
        frequency = tx.frequency
        isRecurringTemplate = tx.isRecurringTemplate
        selectedCategory = tx.category
        sourceAccount = tx.sourceAccount
        destinationAccount = tx.destinationAccount
        selectedGoal = tx.savingGoal

        switch tx.type {
        case .income:          mainSegment = 0
        case .expense:         mainSegment = 1
        case .savingDeposit:   mainSegment = 2; savingSegment = 0
        case .savingWithdrawal:mainSegment = 2; savingSegment = 1
        case .transfer:        mainSegment = 3
        }
    }

    private func save() {
        errors = []
        let type = resolvedType()
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)

        if amount <= 0 { errors.append("Vul een bedrag groter dan 0 in.") }

        switch type {
        case .income:
            if selectedCategory == nil   { errors.append("Kies een categorie.") }
            if destinationAccount == nil { errors.append("Kies een rekening (komt bij).") }
        case .expense:
            if selectedCategory == nil { errors.append("Kies een categorie.") }
            if sourceAccount == nil    { errors.append("Kies een rekening (gaat af).") }
        case .transfer:
            if sourceAccount == nil      { errors.append("Kies een bronrekening.") }
            if destinationAccount == nil { errors.append("Kies een bestemmingsrekening.") }
            if let s = sourceAccount, let d = destinationAccount, s == d {
                errors.append("Bron- en bestemmingsrekening moeten verschillend zijn.")
            }
        case .savingDeposit:
            if selectedGoal == nil  { errors.append("Kies een spaarpot.") }
            if sourceAccount == nil { errors.append("Kies een bronrekening.") }
        case .savingWithdrawal:
            if selectedGoal == nil       { errors.append("Kies een spaarpot.") }
            if destinationAccount == nil { errors.append("Kies een bestemmingsrekening.") }
        }

        if isRecurringTemplate && frequency == .none {
            errors.append("Kies een frequentie voor een terugkerende transactie.")
        }

        if !errors.isEmpty { showErrorAlert = true; return }

        let draft = Transaction(type: type, amount: amount, date: date,
                                frequency: frequency, isRecurringTemplate: isRecurringTemplate)
        draft.descriptionText = trimmed
        draft.category = nil; draft.sourceAccount = nil
        draft.destinationAccount = nil; draft.savingGoal = nil

        switch type {
        case .income:          draft.category = selectedCategory; draft.destinationAccount = destinationAccount
        case .expense:         draft.category = selectedCategory; draft.sourceAccount = sourceAccount
        case .transfer:        draft.sourceAccount = sourceAccount; draft.destinationAccount = destinationAccount
        case .savingDeposit:   draft.sourceAccount = sourceAccount; draft.savingGoal = selectedGoal
        case .savingWithdrawal:draft.destinationAccount = destinationAccount; draft.savingGoal = selectedGoal
        }

        let validationErrors = draft.validate()
        if !validationErrors.isEmpty { errors = validationErrors; showErrorAlert = true; return }

        if let existing = transactionToEdit {
            existing.type = draft.type; existing.amount = draft.amount
            existing.date = draft.date; existing.frequency = draft.frequency
            existing.isRecurringTemplate = draft.isRecurringTemplate
            existing.descriptionText = draft.descriptionText
            existing.category = draft.category; existing.sourceAccount = draft.sourceAccount
            existing.destinationAccount = draft.destinationAccount; existing.savingGoal = draft.savingGoal
        } else {
            context.insert(draft)
        }

        try? context.save()
        FinanceEngine.recalculateAll(context: context)
        dismiss()
    }

    private func resolvedType() -> TransactionType {
        if mainSegment == 0 { return .income }
        if mainSegment == 1 { return .expense }
        if mainSegment == 2 { return savingSegment == 0 ? .savingDeposit : .savingWithdrawal }
        return .transfer
    }

    private func applyPresetIfNeeded() {
        switch preset {
        case .none:                  mainSegment = 1
        case .income(let acc):       mainSegment = 0; destinationAccount = acc
        case .expense(let acc):      mainSegment = 1; sourceAccount = acc
        case .transfer(let acc):     mainSegment = 3; sourceAccount = acc
        case .savingDeposit(let g):  mainSegment = 2; savingSegment = 0; selectedGoal = g
        case .savingWithdrawal(let g):mainSegment = 2; savingSegment = 1; selectedGoal = g
        }
    }

    private func resolveDefaultAccount() -> Account? {
        accounts.first(where: { !$0.isArchived && $0.isDefault })
        ?? accounts.first(where: { !$0.isArchived })
    }
}
