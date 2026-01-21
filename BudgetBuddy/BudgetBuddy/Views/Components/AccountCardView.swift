import SwiftUI
import _SwiftData_SwiftUI

// /Views/Components/AccountCardView.swift

struct AccountCardView: View {
    let account: Account
    let currencyCode: String
    @Query private var transactions: [Transaction]


    var body: some View {
        HStack(spacing: 14) {

            // 🔵 Account circle with icon
            ZStack {
                Circle()
                    .fill(
                        AppTheme.color(from: account.colorHex)
                        ?? AppTheme.brand
                    )

                Image(systemName: account.effectiveIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.headline)

                Text(account.type.uiLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {

                Text(
                    MoneyFormatter.format(
                        FinanceEngine.accountBalance(account, transactions: transactions)
                    )
                )
                .font(.headline)

                if account.isArchived {
                    Text("Inactief")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(AppTheme.cardBg)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
        )
    }
}
