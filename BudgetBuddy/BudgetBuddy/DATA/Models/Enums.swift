// /Data/Models/Enums.swift

import Foundation

enum TransactionType: String, Codable, Identifiable, CaseIterable {
    case income, expense, transfer, savingDeposit, savingWithdrawal
    var id: String { rawValue }

    var uiTitle: String {
        switch self {
        case .income: return "Inkomst"
        case .expense: return "Uitgave"
        case .transfer: return "Overboeking"
        case .savingDeposit: return "Storting spaarpot"
        case .savingWithdrawal: return "Opname spaarpot"
        }
    }
}

enum TransactionFrequency: String, Codable, Identifiable, CaseIterable {
    case none, weekly, monthly, quarterly, fourMonthly, sixMonthly, yearly
    var id: String { rawValue }

    var uiLabel: String {
        switch self {
        case .none: return "Enkel vandaag"
        case .weekly: return "Elke week"
        case .monthly: return "Elke maand"
        case .quarterly: return "Elke 3 maand"
        case .fourMonthly: return "Elke 4 maand"
        case .sixMonthly: return "Elke 6 maand"
        case .yearly: return "Jaarlijks"
        }
    }
}

enum AccountType: String, Codable, Identifiable, CaseIterable {
    case checking, savings, cash, other
    var id: String { rawValue }

    var uiLabel: String {
        switch self {
        case .checking: return "Zichtrekening"
        case .savings: return "Spaarrekening"
        case .cash: return "Cash"
        case .other: return "Overig"
        }
    }

    var defaultIcon: String {
        switch self {
        case .checking: return "creditcard.fill"
        case .savings: return "banknote.fill"
        case .cash: return "banknote"
        case .other: return "tray.full.fill"
        }
    }
}

enum PeriodType: String, Codable, Identifiable, CaseIterable {
    case week, month, year
    var id: String { rawValue }

    var uiLabel: String {
        switch self {
        case .week: return "Per week"
        case .month: return "Per maand"
        case .year: return "Per jaar"
        }
    }
}
