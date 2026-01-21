import SwiftUI
import SwiftData

struct PeriodOverviewView: View {
    @Query private var transactions: [Transaction]

    @State private var selectedMode: Int = 0   // 0 = per periode, 1 = net worth
    @State private var period: PeriodType = .month
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    private var rows: [PeriodSummary] {
        FinanceEngine.periodSummaries(
            transactions: transactions,
            period: period,
            year: selectedYear
        )
    }

    var body: some View {
        VStack(spacing: 0) {

            // 🔝 LARGE TITLE HEADER (bigger than nav title)
            VStack(spacing: 12) {
                Text("Overzicht")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // ✅ SINGLE MODE SELECTOR (ONLY ONE)
                SegmentedControl(
                    items: ["Per periode", "Net worth"],
                    selectedIndex: $selectedMode
                )

                if selectedMode == 0 {
                    SegmentedControl(
                        items: ["Week", "Maand", "Jaar"],
                        selectedIndex: Binding(
                            get: {
                                period == .week ? 0 : period == .month ? 1 : 2
                            },
                            set: {
                                period = $0 == 0 ? .week : $0 == 1 ? .month : .year
                            }
                        )
                    )

                    Text("Overzicht per \(periodTitle)")
                        .font(.headline)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal)
            .background(Color(.systemBackground))

            // 📊 CONTENT
            List {
                if selectedMode == 0 {
                    if rows.isEmpty {
                        EmptyStateView(
                            icon: "chart.bar",
                            title: "Geen gegevens",
                            message: "Er zijn nog geen transacties voor deze periode"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(rows, id: \.id) { row in
                            VStack(alignment: .leading, spacing: 10) {

                                HStack {
                                    Text(row.label)
                                        .font(.headline)

                                    Spacer()

                                    Text(MoneyFormatter.format(row.net))
                                        .foregroundColor(
                                            row.net >= 0 ? AppTheme.positive : AppTheme.negative
                                        )
                                }

                                BarChartView(
                                    items: [
                                        BarChartItem(
                                            label: "",
                                            income: NSDecimalNumber(decimal: row.income).doubleValue,
                                            expense: NSDecimalNumber(decimal: row.expense).doubleValue
                                        )
                                    ]
                                )
                                .frame(height: 10)
                            }
                            .padding(.vertical, 10)
                        }
                    }
                } else {
                    NetWorthOverviewView()
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Helpers

    private var periodTitle: String {
        switch period {
        case .week:
            return "week"
        case .month:
            return "maand"
        case .year:
            return "jaar"
        }
    }
}
