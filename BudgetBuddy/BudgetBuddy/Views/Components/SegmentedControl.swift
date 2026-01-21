// /Views/Components/SegmentedControl.swift

import SwiftUI

struct SegmentedControl: View {
    let items: [String]
    @Binding var selectedIndex: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(items.indices, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedIndex = index
                    }
                } label: {
                    Text(items[index])
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(selectedIndex == index ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedIndex == index ? AppTheme.brand : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}
