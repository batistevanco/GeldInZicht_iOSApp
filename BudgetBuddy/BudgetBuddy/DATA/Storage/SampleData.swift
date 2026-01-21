// /Data/Storage/SampleData.swift
// /Data/Storage/SampleData.swift
//
// Seed data for FIRST LAUNCH ONLY.
// This file is NOT mock/demo data.
// It only provides default categories that every user starts with.
// No accounts, transactions or savings are created here.
//

import SwiftData
import Foundation

enum SampleData {

    /// Ensures default categories exist on first launch.
    /// This runs safely on every app start but only inserts data once.
    static func ensureOnboardingData(context: ModelContext) {

        // Prevent duplicates: if at least one category exists, do nothing
        let existingCategories = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        guard existingCategories.isEmpty else { return }

        // MARK: - Default Categories (Seed Data)
        let categories: [Category] = [
            Category(
                name: "Werk",
                iconName: "briefcase.fill",
                isDefault: true
            ),
            Category(
                name: "Boodschappen",
                iconName: "cart.fill",
                isDefault: true
            ),
            Category(
                name: "Huur",
                iconName: "house.fill",
                isDefault: true
            ),
            Category(
                name: "Vrije tijd",
                iconName: "gamecontroller.fill",
                isDefault: true
            ),
            Category(
                name: "Abonnementen",
                iconName: "repeat",
                isDefault: true
            ),
            Category(
                name: "Transport",
                iconName: "car.fill",
                isDefault: true
            )
        ]

        categories.forEach { context.insert($0) }

        do {
            try context.save()
        } catch {
            assertionFailure("Failed to insert default categories: \(error)")
        }
    }
}
