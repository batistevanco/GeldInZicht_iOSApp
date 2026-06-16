// /App/RootTabView.swift

import SwiftUI

struct RootTabView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView()
            }
            .tabItem { Label("Dashboard", systemImage: "house.fill") }
            .tag(0)

            NavigationStack {
                TransactionsListView()
            }
            .tabItem { Label("Transacties", systemImage: "list.bullet.rectangle") }
            .tag(1)

            NavigationStack {
                AccountsOverviewView()
            }
            .tabItem { Label("Rekeningen", systemImage: "creditcard.fill") }
            .tag(2)

            NavigationStack {
                MoreView()
            }
            .tabItem { Label("Meer", systemImage: "ellipsis.circle.fill") }
            .tag(3)
        }
        .tint(Color(red: 0.10, green: 0.12, blue: 0.18))
        .environment(\.selectedTab, $selectedTab)
    }
}

// MARK: - Environment key

private struct SelectedTabKey: EnvironmentKey {
    static let defaultValue: Binding<Int> = .constant(0)
}

extension EnvironmentValues {
    var selectedTab: Binding<Int> {
        get { self[SelectedTabKey.self] }
        set { self[SelectedTabKey.self] = newValue }
    }
}
