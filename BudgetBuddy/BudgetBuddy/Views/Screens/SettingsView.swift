//
//  SettingsView.swift
//  BudgetBuddy
//
//  Created by Batiste Vancoillie on 20/01/2026.
//


import SwiftUI
import SwiftData

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [AppSettings]
    @Query(sort: \Account.name) private var accounts: [Account]

    private var appSettings: AppSettings {
        if let existing = settings.first {
            return existing
        } else {
            let new = AppSettings()
            context.insert(new)
            return new
        }
    }

    var body: some View {
        Form {

            // MARK: - General
            Section(header: FormSectionHeader(title: "Algemeen")) {

                Toggle(
                    "Saldo overzetten",
                    isOn: Binding(
                        get: { appSettings.carryOverBalance },
                        set: { newValue in
                            appSettings.carryOverBalance = newValue
                            try? context.save()
                        }
                    )
                )

                Text("""
Wanneer deze optie is ingeschakeld, wordt het eindsaldo van de vorige maand automatisch meegenomen als startsaldo van de volgende maand.

Voorbeeld:
• Je eindigt januari met +€250
• Februari start dan automatisch met +€250

Als je deze optie uitschakelt, begint elke nieuwe maand opnieuw vanaf €0, ongeacht het saldo van de vorige maand.
""")
                .font(.caption)
                .foregroundColor(.secondary)

                if appSettings.carryOverBalance {

                    Toggle(
                        "Saldo automatisch op rekening plaatsen",
                        isOn: Binding(
                            get: { appSettings.carryOverToAccount },
                            set: { newValue in
                                appSettings.carryOverToAccount = newValue
                                try? context.save()
                            }
                        )
                    )

                    if appSettings.carryOverToAccount {

                        Picker(
                            "Rekening voor overdracht",
                            selection: Binding(
                                get: {
                                    appSettings.carryOverAccountID
                                },
                                set: { newValue in
                                    appSettings.carryOverAccountID = newValue
                                    try? context.save()
                                }
                            )
                        ) {
                            Text("Kies een rekening").tag(UUID?.none)

                            ForEach(accounts.filter { !$0.isArchived }) { account in
                                Text(account.name).tag(Optional(account.id))
                            }
                        }

                        Text("""
Wanneer deze optie is ingeschakeld, wordt het eindsaldo van de maand automatisch als storting toegevoegd aan de gekozen rekening.

Voorbeeld:
• Januari eindigt met +€250
• Op het einde van de maand wordt automatisch een storting van €250 toegevoegd aan de geselecteerde rekening
• Februari start met €0, maar de rekening bevat wel het overgedragen bedrag

Dit is handig als je je saldo effectief wil laten doorlopen op een specifieke rekening, zoals je zichtrekening.
""")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }

            // MARK: - Categories
            Section {
                NavigationLink("Categorieën beheren") {
                    CategoriesManagementView()
                }
            }
        }
        .navigationTitle("Instellingen")
        .navigationBarTitleDisplayMode(.inline)
    }
}
