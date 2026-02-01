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

                    // 1. Ensure AppSettings + default data exist
                    SampleData.ensureOnboardingData(context: context)

                    // 2. Generate recurring transactions (throttled per day)
                    RecurringTransactionEngine.run(context: context)

                    // 3. Apply monthly carry-over (safe + duplicate-proof)
                    FinanceEngine.applyMonthlyCarryOverIfNeeded(context: context)
                }
        }
        .modelContainer(container)
    }
}
