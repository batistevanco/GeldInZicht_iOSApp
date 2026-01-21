//
//  OverviewHubView.swift
//  BudgetBuddy
//
//  Created by Batiste Vancoillie on 20/01/2026.
//


// /Views/Screens/OverviewHubView.swift

import SwiftUI

struct OverviewHubView: View {
    @State private var selected = 0

    var body: some View {
        VStack(spacing: 12) {
            SegmentedControl(
                items: ["Per periode", "Net worth"],
                selectedIndex: $selected
            )
            .padding(.horizontal)

            if selected == 0 {
                PeriodOverviewView()
            } else {
                NetWorthOverviewView()
            }
        }
        .navigationTitle("Overzicht")
        .navigationBarTitleDisplayMode(.inline)
    }
}