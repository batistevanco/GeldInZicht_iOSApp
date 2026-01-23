// /App/RootTabView.swift

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                BudgetOverviewView()
            }
            .tabItem {
                Label("IN/OUT", systemImage: "list.bullet.rectangle")
            }

            NavigationStack {
                AccountsOverviewView()
            }
            .tabItem {
                Label("Accounts", systemImage: "creditcard")
            }

            NavigationStack {
                PeriodOverviewView()
            }
            .tabItem {
                Label("Overzicht", systemImage: "chart.bar")
            }

            NavigationStack {
                HelpView()
            }
            .tabItem {
                Label("Help", systemImage: "questionmark.circle")
            }
        }
    }
}
