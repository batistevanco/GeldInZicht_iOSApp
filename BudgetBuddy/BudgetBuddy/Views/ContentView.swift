//
//  ContentView.swift
//  BudgetBuddy
//
//  Created by Batiste Vancoillie on 20/01/2026.
//


// ContentView.swift (nieuw klein bestand)

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var settings: [AppSettings]

    var body: some View {
        if settings.first?.hasOnboardingCompleted == true {
            RootTabView()
        } else {
            OnboardingFlowView()
        }
    }
}