// /Views/Screens/MoreView.swift

import SwiftUI

struct MoreView: View {
    var body: some View {
        List {
            Section("Inzichten") {
                NavigationLink {
                    InsightsView()
                } label: {
                    moreRow(icon: "lightbulb.fill", color: .yellow, title: "Inzichten")
                }

                NavigationLink {
                    YearOverviewView()
                } label: {
                    moreRow(icon: "calendar", color: AppTheme.brand, title: "Jaaroverzicht")
                }

                NavigationLink {
                    FinancialTimelineView()
                } label: {
                    moreRow(icon: "clock.fill", color: .teal, title: "Financiële tijdlijn")
                }

                NavigationLink {
                    NetWorthOverviewView()
                } label: {
                    moreRow(icon: "chart.line.uptrend.xyaxis", color: .purple, title: "Netto vermogen")
                }
            }

            Section("Plannen") {
                NavigationLink {
                    SavingGoalsOverviewView()
                } label: {
                    moreRow(icon: "star.fill", color: .orange, title: "Spaardoelen")
                }

                NavigationLink {
                    RecurringTransactionsView()
                } label: {
                    moreRow(icon: "repeat.circle.fill", color: .indigo, title: "Terugkerende transacties")
                }
            }

            Section("Beheer") {
                NavigationLink {
                    CategoriesManagementView()
                } label: {
                    moreRow(icon: "tag.fill", color: .teal, title: "Categorieën")
                }

                NavigationLink {
                    SettingsView()
                } label: {
                    moreRow(icon: "gearshape.fill", color: .gray, title: "Instellingen")
                }

                NavigationLink {
                    HelpView()
                } label: {
                    moreRow(icon: "questionmark.circle.fill", color: .blue, title: "Help")
                }
            }
        }
        .navigationTitle("Meer")
        .navigationBarTitleDisplayMode(.large)
    }

    private func moreRow(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 8).fill(color))

            Text(title)
                .font(.body)
        }
        .padding(.vertical, 2)
    }
}
