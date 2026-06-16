// /Views/Screens/DataManagementView.swift

import SwiftUI
import SwiftData

struct DataManagementView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [AppSettings]

    @State private var showResetConfirm = false
    @State private var showOnboardingConfirm = false

    var body: some View {
        List {
            Section {
                Text("Hier kan je alle app-data beheren. Acties zijn onomkeerbaar.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 8, trailing: 0))
            }

            Section(header: Text("Onboarding")) {
                Button {
                    showOnboardingConfirm = true
                } label: {
                    Label("Onboarding opnieuw doen", systemImage: "arrow.counterclockwise")
                        .foregroundStyle(.primary)
                }
            }

            Section(header: Text("Gegevens")) {
                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Label("Alle data verwijderen", systemImage: "trash.fill")
                }
            }
        }
        .navigationTitle("Data")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog(
            "Onboarding opnieuw doen?",
            isPresented: $showOnboardingConfirm,
            titleVisibility: .visible
        ) {
            Button("Opnieuw doen", role: .destructive) {
                resetOnboarding()
            }
            Button("Annuleren", role: .cancel) {}
        } message: {
            Text("Je data blijft bewaard. Je wordt teruggestuurd naar het welkomstscherm.")
        }
        .confirmationDialog(
            "Alle data verwijderen?",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Alles verwijderen", role: .destructive) {
                resetAll()
            }
            Button("Annuleren", role: .cancel) {}
        } message: {
            Text("Dit verwijdert al je rekeningen, transacties en spaardoelen. Dit kan niet ongedaan worden gemaakt.")
        }
    }

    private func resetOnboarding() {
        guard let s = settings.first else { return }
        s.hasOnboardingCompleted = false
        try? context.save()
    }

    private func resetAll() {
        try? context.delete(model: Transaction.self)
        try? context.delete(model: SavingGoal.self)
        try? context.delete(model: Account.self)
        try? context.delete(model: Category.self)
        try? context.delete(model: AppSettings.self)
        try? context.save()
    }
}
