// /Views/Onboarding/OnboardingCarryOverView.swift

import SwiftUI
import SwiftData

struct OnboardingCarryOverView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [AppSettings]
    @Query private var accounts: [Account]

    let onFinish: () -> Void

    private var appSettings: AppSettings? { settings.first }

    var body: some View {
        VStack(spacing: 0) {

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Header
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Saldo-instellingen")
                            .font(.system(size: 30, weight: .bold))

                        Text("Hoe wil je omgaan met je saldo aan het einde van de maand?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)

                    // Optie 1: Saldo overzetten
                    settingCard(
                        icon: "arrow.uturn.right",
                        iconColor: Color(red: 0.30, green: 0.55, blue: 1.0),
                        title: "Saldo overzetten",
                        description: "Het eindsaldo van de vorige maand wordt meegenomen als startsaldo van de volgende maand.\n\nVoorbeeld: je eindigt januari met +€250 → februari start automatisch met +€250."
                    ) {
                        if let s = appSettings {
                            Toggle("", isOn: Binding(
                                get: { s.carryOverBalance },
                                set: { s.carryOverBalance = $0; try? context.save() }
                            ))
                            .labelsHidden()
                            .tint(Color(red: 0.10, green: 0.12, blue: 0.18))
                        }
                    }

                    // Optie 2: Op rekening plaatsen
                    if appSettings?.carryOverBalance == true {
                        settingCard(
                            icon: "banknote",
                            iconColor: Color(red: 0.20, green: 0.75, blue: 0.50),
                            title: "Saldo op rekening plaatsen",
                            description: "Het overgedragen saldo wordt automatisch als storting toegevoegd aan een gekozen rekening."
                        ) {
                            if let s = appSettings {
                                Toggle("", isOn: Binding(
                                    get: { s.carryOverToAccount },
                                    set: { s.carryOverToAccount = $0; try? context.save() }
                                ))
                                .labelsHidden()
                                .tint(Color(red: 0.10, green: 0.12, blue: 0.18))
                            }
                        }

                        // Rekening picker
                        if appSettings?.carryOverToAccount == true {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Rekening voor overdracht")
                                    .font(.subheadline.weight(.semibold))

                                if let s = appSettings {
                                    Picker("Rekening", selection: Binding(
                                        get: { s.carryOverAccountID },
                                        set: { s.carryOverAccountID = $0; try? context.save() }
                                    )) {
                                        Text("Kies een rekening").tag(Optional<UUID>.none)
                                        ForEach(accounts.filter { !$0.isArchived }) { acc in
                                            Text(acc.name).tag(Optional(acc.id))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(.primary)
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color(.secondarySystemBackground))
                                    )
                                }
                            }
                        }
                    }

                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 24)
            }

            // Start knop
            Button(action: onFinish) {
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

    private func settingCard<T: View>(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        @ViewBuilder toggle: () -> T
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(iconColor.opacity(0.12))
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                .frame(width: 38, height: 38)

                Text(title)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                toggle()
            }

            Divider()

            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
