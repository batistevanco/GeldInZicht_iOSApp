// /Views/Components/PrimaryButton.swift

import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline)
                }

                Text(title.uppercased())
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isEnabled ? AppTheme.brand : Color.gray.opacity(0.35))
            .foregroundColor(.black)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(!isEnabled)
    }
}
