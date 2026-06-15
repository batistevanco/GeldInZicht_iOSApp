// /App/RootTabView.swift

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }

            NavigationStack {
                TransactionsListView()
            }
            .tabItem {
                Label("Transacties", systemImage: "list.bullet.rectangle")
            }

            NavigationStack {
                AccountsOverviewView()
            }
            .tabItem {
                Label("Rekeningen", systemImage: "creditcard.fill")
            }

            NavigationStack {
                MoreView()
            }
            .tabItem {
                Label("Meer", systemImage: "ellipsis.circle.fill")
            }
        }
        .tint(AppTheme.brand)
    }
}
