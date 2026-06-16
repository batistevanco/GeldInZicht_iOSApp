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

        // Probeer eerst met CloudKit sync
        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        if let container = try? ModelContainer(for: schema, configurations: [cloudConfig]) {
            return container
        }

        // Fallback: lokale opslag zonder CloudKit (bv. simulator zonder iCloud)
        let localConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [localConfig])
        } catch {
            fatalError("❌ SwiftData container failed to initialize: \(error)")
        }
    }
}
