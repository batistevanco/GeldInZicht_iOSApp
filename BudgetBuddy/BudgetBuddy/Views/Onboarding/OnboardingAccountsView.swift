// /Views/Onboarding/OnboardingAccountsView.swift

import SwiftUI
import SwiftData

struct OnboardingAccountsView: View {
    @Environment(\.modelContext) private var context
    @Query private var accounts: [Account]

    @State private var showAddAccount = false
    let onFinish: () -> Void

    private func ensureDefaultAccount() {
        guard !accounts.isEmpty else { return }
        if accounts.contains(where: { $0.isDefault }) { return }
        let candidate = accounts.first(where: { !$0.isArchived }) ?? accounts[0]
        candidate.isDefault = true
        try? context.save()
    }

    var body: some View {
        VStack(spacing: 0) {

            // Header
            VStack(alignment: .leading, spacing: 10) {
                Text("Jouw rekeningen")
                    .font(.system(size: 30, weight: .bold))

                Text("Voeg minstens één rekening toe. Je kan er altijd meer toevoegen later.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            // Rekeningen lijst of lege staat
            ScrollView {
                if accounts.isEmpty {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(.secondarySystemBackground))
                                .frame(width: 80, height: 80)
                            Image(systemName: "creditcard")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        Text("Nog geen rekening")
                            .font(.headline)
                        Text("Voeg je eerste rekening toe om te beginnen.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    VStack(spacing: 10) {
                        ForEach(accounts) { account in
                            onboardingAccountRow(account)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                }
            }

            Spacer()

            // Knoppen
            VStack(spacing: 10) {
                // Rekening toevoegen (omlijnd)
                Button { showAddAccount = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Rekening toevoegen")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color(.separator), lineWidth: 1.5)
                    )
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)

                // Start knop – zelfde stijl als welcome
                Button {
                    ensureDefaultAccount()
                    onFinish()
                } label: {
                    HStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(Color(white: 0.28))
                                .frame(width: 42, height: 42)
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .padding(.leading, 6)

                        Text("Start met GeldInZicht")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.trailing, 48)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        Capsule()
                            .fill(accounts.isEmpty
                                  ? Color(red: 0.10, green: 0.12, blue: 0.18).opacity(0.35)
                                  : Color(red: 0.10, green: 0.12, blue: 0.18))
                    )
                }
                .buttonStyle(.plain)
                .disabled(accounts.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .padding(.top, 12)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .onAppear { ensureDefaultAccount() }
        .onChange(of: accounts.count) { ensureDefaultAccount() }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showAddAccount) { AddEditAccountView() }
    }

    private func onboardingAccountRow(_ account: Account) -> some View {
        let color = AppTheme.color(from: account.colorHex) ?? AppTheme.brand
        return HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.12))
                Image(systemName: account.effectiveIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(account.name)
                    .font(.subheadline.weight(.semibold))
                Text(account.type.uiLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if account.isDefault {
                Text("Standaard")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(color.opacity(0.12)))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
