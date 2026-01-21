// /App/BudgetBuddyApp.swift

import SwiftUI
import SwiftData

@main
struct BudgetBuddyApp: App {

    let container = PersistenceController.makeContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    let context = container.mainContext

                    SampleData.ensureOnboardingData(context: context)

                    // 🔁 RECURRING TRANSACTIES GENEREREN
                    RecurringTransactionEngine.run(context: context)

                    // 🔁 MAANDELIJKS SALDO OVERZETTEN (optioneel → rekening)
                    FinanceEngine.applyMonthlyCarryOverIfNeeded(context: context)
                }
        }
        .modelContainer(container)
    }
}
