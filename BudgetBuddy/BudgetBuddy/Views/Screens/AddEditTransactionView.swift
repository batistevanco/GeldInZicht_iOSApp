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

    @State private var amount: Decimal = 0
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

    // NEW TRANSACTION
    init(preset: Preset = .none) {
        self.preset = preset
        self.transactionToEdit = nil
    }

    // EDIT TRANSACTION
    init(transaction: Transaction) {
        self.preset = .none
        self.transactionToEdit = transaction
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $mainSegment) {
                        Text("IN").tag(0)
                        Text("UIT").tag(1)
                        Text("SPAREN").tag(2)
                        Text("TRANSFER").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .disabled(transactionToEdit != nil) // type vast bij bewerken
                }

                Section(header: FormSectionHeader(title: "Bedrag")) {
                    TextField("0,00", value: $amount, format: .number)
                        .keyboardType(.decimalPad)
                    Text(MoneyFormatter.format(amount, currencyCode: currencyCode))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(header: FormSectionHeader(title: "Details")) {
                    TextField("Omschrijving (optioneel)", text: $description)
                    DatePicker("Datum", selection: $date, displayedComponents: .date)

                    Picker("Frequentie", selection: $frequency) {
                        ForEach(TransactionFrequency.allCases) { f in
                            Text(f.uiLabel).tag(f)
                        }
                    }

                    Toggle("Opslaan als terugkerende transactie", isOn: $isRecurringTemplate)
                }

                if mainSegment == 0 { incomeSection }
                if mainSegment == 1 { expenseSection }
                if mainSegment == 2 { savingSection }
                if mainSegment == 3 { transferSection }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(transactionToEdit == nil ? "Nieuwe transactie" : "Transactie bewerken")
            .alert("Kan transactie niet opslaan", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errors.joined(separator: "\n"))
            }
            .sheet(isPresented: $showCategoryManager) {
                NavigationStack {
                    CategoriesManagementView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleren") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Opslaan") { save() }
                }
                if transactionToEdit != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .onAppear {
                if let tx = transactionToEdit {
                    load(from: tx)
                    // Ensure recurring onboarding income shows correct defaults
                    if tx.isRecurringTemplate {
                        isRecurringTemplate = true
                        if tx.frequency == .none {
                            frequency = .monthly
                        }
                    }
                } else {
                    applyPresetIfNeeded()

                    let defaultAccount = resolveDefaultAccount()

                    switch mainSegment {
                    case 1: // UIT
                        sourceAccount = sourceAccount ?? defaultAccount
                    case 2: // SPAREN
                        if savingSegment == 0 {
                            sourceAccount = sourceAccount ?? defaultAccount
                        } else {
                            destinationAccount = destinationAccount ?? defaultAccount
                        }
                    case 3: // TRANSFER
                        sourceAccount = sourceAccount ?? defaultAccount
                    default:
                        break
                    }
                }
            }
        }
        .alert("Transactie verwijderen?", isPresented: $showDeleteConfirm) {
            Button("Verwijderen", role: .destructive) {
                if let tx = transactionToEdit {
                    context.delete(tx)
                    try? context.save()
                    FinanceEngine.recalculateAll(context: context)
                    dismiss()
                }
            }
            Button("Annuleren", role: .cancel) { }
        } message: {
            Text("Deze transactie wordt definitief verwijderd.")
        }
    }

    // MARK: - Sections
    private var incomeSection: some View {
        Section(header: FormSectionHeader(title: "Inkomen")) {
            Picker("Categorie", selection: $selectedCategory) {
                Text("Kies…").tag(Category?.none)
                ForEach(categories) { c in
                    Text(c.name).tag(Category?.some(c))
                }
            }

            Button {
                showCategoryManager = true
            } label: {
                Label("Nieuwe categorie toevoegen", systemImage: "plus.circle")
            }

            Picker("Rekening (komt bij)", selection: $destinationAccount) {
                Text("Kies…").tag(Account?.none)
                ForEach(accounts.filter { !$0.isArchived }) { a in
                    Text(a.name).tag(Account?.some(a))
                }
            }
        }
    }

    private var expenseSection: some View {
        Section(header: FormSectionHeader(title: "Uitgave")) {
            Picker("Categorie", selection: $selectedCategory) {
                Text("Kies…").tag(Category?.none)
                ForEach(categories) { c in
                    Text(c.name).tag(Category?.some(c))
                }
            }

            Button {
                showCategoryManager = true
            } label: {
                Label("Nieuwe categorie toevoegen", systemImage: "plus.circle")
            }

            Picker("Rekening (gaat af)", selection: $sourceAccount) {
                Text("Kies…").tag(Account?.none)
                ForEach(accounts.filter { !$0.isArchived }) { a in
                    Text(a.name).tag(Account?.some(a))
                }
            }
        }
    }
    private var savingSection: some View {
        Section(header: FormSectionHeader(title: "Spaarpot")) {
            Picker("Richting", selection: $savingSegment) {
                Text("Storten").tag(0)
                Text("Opnemen").tag(1)
            }
            .pickerStyle(.segmented)

            Picker("Spaarpot", selection: $selectedGoal) {
                Text("Kies…").tag(SavingGoal?.none)
                ForEach(goals.filter { !$0.isArchived }) { g in
                    Text(g.name).tag(SavingGoal?.some(g))
                }
            }

            if savingSegment == 0 {
                Picker("Bronrekening", selection: $sourceAccount) {
                    Text("Kies…").tag(Account?.none)
                    ForEach(accounts.filter { !$0.isArchived }) { a in
                        Text(a.name).tag(Account?.some(a))
                    }
                }
            } else {
                Picker("Bestemmingsrekening", selection: $destinationAccount) {
                    Text("Kies…").tag(Account?.none)
                    ForEach(accounts.filter { !$0.isArchived }) { a in
                        Text(a.name).tag(Account?.some(a))
                    }
                }
            }
        }
    }
    private var transferSection: some View {
        Section(header: FormSectionHeader(title: "Overboeking")) {
            Picker("Van", selection: $sourceAccount) {
                Text("Kies…").tag(Account?.none)
                ForEach(accounts.filter { !$0.isArchived }) { a in
                    Text(a.name).tag(Account?.some(a))
                }
            }
            Picker("Naar", selection: $destinationAccount) {
                Text("Kies…").tag(Account?.none)
                ForEach(accounts.filter { !$0.isArchived }) { a in
                    Text(a.name).tag(Account?.some(a))
                }
            }
        }
    }

    // MARK: - Load existing transaction
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
        case .income: mainSegment = 0
        case .expense: mainSegment = 1
        case .savingDeposit:
            mainSegment = 2
            savingSegment = 0
        case .savingWithdrawal:
            mainSegment = 2
            savingSegment = 1
        case .transfer:
            mainSegment = 3
        }
    }

    private func save() {
        errors = []

        let type = resolvedType()

        // ✅ HARD GATE: nooit opslaan/inserten als verplichte velden ontbreken
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        // Bedrag
        if amount <= 0 {
            errors.append("Vul een bedrag groter dan 0 in.")
        }

        // Type-specifieke vereisten
        switch type {
        case .income:
            if selectedCategory == nil {
                errors.append("Kies een categorie.")
            }
            if destinationAccount == nil {
                errors.append("Kies een rekening (komt bij).")
            }

        case .expense:
            if selectedCategory == nil {
                errors.append("Kies een categorie.")
            }
            if sourceAccount == nil {
                errors.append("Kies een rekening (gaat af).")
            }

        case .transfer:
            if sourceAccount == nil {
                errors.append("Kies een bronrekening.")
            }
            if destinationAccount == nil {
                errors.append("Kies een bestemmingsrekening.")
            }
            if let s = sourceAccount, let d = destinationAccount, s == d {
                errors.append("Bron- en bestemmingsrekening moeten verschillend zijn.")
            }

        case .savingDeposit:
            if selectedGoal == nil {
                errors.append("Kies een spaarpot.")
            }
            if sourceAccount == nil {
                errors.append("Kies een bronrekening.")
            }

        case .savingWithdrawal:
            if selectedGoal == nil {
                errors.append("Kies een spaarpot.")
            }
            if destinationAccount == nil {
                errors.append("Kies een bestemmingsrekening.")
            }
        }

        // Terugkerende transactie: frequentie moet ingevuld zijn
        if isRecurringTemplate && frequency == .none {
            errors.append("Kies een frequentie voor een terugkerende transactie.")
        }

        if !errors.isEmpty {
            showErrorAlert = true
            return
        }

        // ❗ Draft object — nog NIET in SwiftData
        let draft = Transaction(
            type: type,
            amount: amount,
            date: date,
            frequency: frequency,
            isRecurringTemplate: isRecurringTemplate
        )

        draft.descriptionText = trimmedDescription

        // Reset relaties
        draft.category = nil
        draft.sourceAccount = nil
        draft.destinationAccount = nil
        draft.savingGoal = nil

        // Koppel volgens type
        switch type {
        case .income:
            draft.category = selectedCategory
            draft.destinationAccount = destinationAccount

        case .expense:
            draft.category = selectedCategory
            draft.sourceAccount = sourceAccount

        case .transfer:
            draft.sourceAccount = sourceAccount
            draft.destinationAccount = destinationAccount

        case .savingDeposit:
            draft.sourceAccount = sourceAccount
            draft.savingGoal = selectedGoal

        case .savingWithdrawal:
            draft.destinationAccount = destinationAccount
            draft.savingGoal = selectedGoal
        }

        // ❗ VALIDATIE — bij fout: STOP
        let validationErrors = draft.validate()
        if !validationErrors.isEmpty {
            errors = validationErrors
            showErrorAlert = true
            return   // ⛔️ STOP — nothing persists
        }

        // ❗ PAS HIER wordt er effectief opgeslagen
        if let existing = transactionToEdit {
            existing.type = draft.type
            existing.amount = draft.amount
            existing.date = draft.date
            existing.frequency = draft.frequency
            existing.isRecurringTemplate = draft.isRecurringTemplate
            existing.descriptionText = draft.descriptionText

            existing.category = draft.category
            existing.sourceAccount = draft.sourceAccount
            existing.destinationAccount = draft.destinationAccount
            existing.savingGoal = draft.savingGoal
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
        case .none:
            mainSegment = 1
        case .income(let acc):
            mainSegment = 0
            destinationAccount = acc
        case .expense(let acc):
            mainSegment = 1
            sourceAccount = acc
        case .transfer(let acc):
            mainSegment = 3
            sourceAccount = acc
        case .savingDeposit(let g):
            mainSegment = 2
            savingSegment = 0
            selectedGoal = g
        case .savingWithdrawal(let g):
            mainSegment = 2
            savingSegment = 1
            selectedGoal = g
        }
    }

    private func resolveDefaultAccount() -> Account? {
        // 1. Expliciete standaardrekening (indien aanwezig)
        if let explicitDefault = accounts.first(where: { !$0.isArchived && $0.isDefault }) {
            return explicitDefault
        }

        // 2. Fallback: eerste actieve rekening
        return accounts.first(where: { !$0.isArchived })
    }
}
