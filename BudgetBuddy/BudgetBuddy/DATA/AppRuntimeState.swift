//
//  AppRuntimeState.swift
//  BudgetBuddy
//
//  Created by Batiste Vancoillie on 01/02/2026.
//


// /Data/AppRuntimeState.swift

import Foundation

/// Runtime-only state that must NOT live in SwiftData
/// This avoids schema-breaking App Store updates when adding new flags or timestamps.
enum AppRuntimeState {

    private static let defaults = UserDefaults.standard

    private enum Keys {
        static let lastRecurringRunAt = "lastRecurringRunAt"
        static let dataFixVersion = "dataFixVersion"
    }

    // MARK: - Recurring transactions

    /// Last date on which recurring transactions were generated.
    /// Used to throttle the engine to max once per day.
    static var lastRecurringRunAt: Date? {
        get {
            defaults.object(forKey: Keys.lastRecurringRunAt) as? Date
        }
        set {
            defaults.set(newValue, forKey: Keys.lastRecurringRunAt)
        }
    }

    // MARK: - Data repair / migration versioning

    /// Version flag for one-time runtime data repairs.
    /// Safe to evolve without touching SwiftData schema.
    static var dataFixVersion: Int {
        get {
            defaults.integer(forKey: Keys.dataFixVersion)
        }
        set {
            defaults.set(newValue, forKey: Keys.dataFixVersion)
        }
    }
}