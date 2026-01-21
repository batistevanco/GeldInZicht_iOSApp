//
//  OnboardingFlowView.swift
//  BudgetBuddy
//
//  Created by Batiste Vancoillie on 20/01/2026.
//


// /Views/Onboarding/OnboardingFlowView.swift

import SwiftUI
import SwiftData

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [AppSettings]

    @State private var step: Int = 0

    private var appSettings: AppSettings {
        settings.first ?? {
            let s = AppSettings()
            context.insert(s)
            return s
        }()
    }

    var body: some View {
        NavigationStack {
            switch step {
            case 0:
                OnboardingAccountsView {
                    appSettings.hasOnboardingCompleted = true
                    try? context.save()
                }
            default:
                EmptyView()
            }
        }
    }
}
