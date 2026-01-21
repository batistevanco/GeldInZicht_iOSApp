//
//  OnboardingAccountsView.swift
//  BudgetBuddy
//
//  Created by Batiste Vancoillie on 20/01/2026.
//

// /Views/Onboarding/OnboardingAccountsView.swift

import SwiftUI
import SwiftData

struct OnboardingAccountsView: View {
    @Environment(\.modelContext) private var context
    @Query private var accounts: [Account]

    @State private var showAddAccount = false

    private func ensureDefaultAccount() {
        // If there are accounts but none marked default, set the first one as default.
        guard !accounts.isEmpty else { return }
        if accounts.contains(where: { $0.isDefault }) { return }

        // Choose the first non-archived account if possible, otherwise first.
        let candidate = accounts.first(where: { !$0.isArchived }) ?? accounts[0]
        candidate.isDefault = true
        try? context.save()
    }

    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: - Titel & uitleg
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rekeningen")
                            .font(.largeTitle.bold())

                        Text("""
                        Om je budget correct te kunnen opvolgen, heb je minstens één rekening nodig.
                        Dit kan een zichtrekening, spaarrekening of cash zijn.
                        """)
                        .font(.body)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // MARK: - Lege staat
                    if accounts.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.blue)

                            Text("Nog geen rekening toegevoegd")
                                .font(.headline)

                            Text("""
                            Voeg minstens één rekening toe zodat inkomsten, uitgaven
                            en spaarpotjes correct kunnen worden gekoppeld.
                            """)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    } else {
                        // MARK: - Bestaande rekeningen
                        VStack(spacing: 12) {
                            ForEach(accounts) { account in
                                AccountCardView(account: account, currencyCode: "EUR")
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }

            // MARK: - Actieknoppen
            VStack(spacing: 12) {
                PrimaryButton(title: "Rekening toevoegen", systemImage: "plus") {
                    showAddAccount = true
                }

                PrimaryButton(title: "Start met GeldInZicht") {
                    ensureDefaultAccount()
                    onFinish()
                }
                .disabled(accounts.isEmpty)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .onAppear {
            ensureDefaultAccount()
        }
        .onChange(of: accounts.count) { _ in
            ensureDefaultAccount()
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showAddAccount) {
            AddEditAccountView()
        }
    }
}
