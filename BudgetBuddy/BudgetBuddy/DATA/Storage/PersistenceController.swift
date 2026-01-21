//
//  PersistenceController.swift
//  BudgetBuddy
//
//  Created by Batiste Vancoillie on 20/01/2026.
//


// /Data/Storage/PersistenceController.swift

import SwiftData

enum PersistenceController {
    static func makeContainer() -> ModelContainer {
        let schema = Schema([
            Transaction.self,
            Account.self,
            Category.self,
            SavingGoal.self,
            AppSettings.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("❌ SwiftData container failed to initialize: \(error)")
        }
    }
}
