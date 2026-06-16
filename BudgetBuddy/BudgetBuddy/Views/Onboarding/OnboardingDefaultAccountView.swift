// /Views/Onboarding/OnboardingDefaultAccountView.swift

import SwiftUI
import SwiftData

struct OnboardingDefaultAccountView: View {
    @Environment(\.modelContext) private var context
    @Query private var accounts: [Account]

    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            // Header
            VStack(alignment: .leading, spacing: 10) {
                Text("Standaard rekening")
                    .font(.system(size: 30, weight: .bold))

                Text("Welke rekening wil je standaard gebruiken bij het toevoegen van transacties?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(accounts.filter { !$0.isArchived }) { account in
                        accountRow(account)
                            .onTapGesture { setDefault(account) }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)
            }

            Spacer()

            Button(action: onNext) {
                HStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(Color(white: 0.28))
                            .frame(width: 42, height: 42)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.leading, 6)

                    Text("Volgende")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.trailing, 48)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(Capsule().fill(Color(red: 0.10, green: 0.12, blue: 0.18)))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .padding(.top, 12)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .navigationBarBackButtonHidden(true)
    }

    private func setDefault(_ account: Account) {
        accounts.forEach { $0.isDefault = ($0.id == account.id) }
        try? context.save()
    }

    private func accountRow(_ account: Account) -> some View {
        let color = AppTheme.color(from: account.colorHex) ?? AppTheme.brand
        let isSelected = account.isDefault

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

            ZStack {
                Circle()
                    .strokeBorder(isSelected ? Color(red: 0.10, green: 0.12, blue: 0.18) : Color(.separator), lineWidth: 2)
                    .frame(width: 24, height: 24)
                if isSelected {
                    Circle()
                        .fill(Color(red: 0.10, green: 0.12, blue: 0.18))
                        .frame(width: 14, height: 14)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isSelected
                      ? Color(red: 0.10, green: 0.12, blue: 0.18).opacity(0.06)
                      : Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isSelected ? Color(red: 0.10, green: 0.12, blue: 0.18).opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
    }
}
