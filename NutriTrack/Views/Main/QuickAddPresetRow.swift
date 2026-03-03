import SwiftUI

// MARK: - QuickAddPresetRow

struct QuickAddPresetRow: View {
    let preset: QuickAddPreset
    let unit: String
    let onTap: () -> Void

    @State private var isAnimating = false

    var body: some View {
        Button(action: {
            onTap()
            triggerAnimation()
        }) {
            Text(preset.displayText(unit: unit))
                .font(Typography.sfPro(size: 14, weight: .medium))
                .foregroundStyle(Color(.label))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
                .scaleEffect(isAnimating ? 1.12 : 1.0)
                .opacity(isAnimating ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Quick add \(preset.displayText(unit: unit))")
        .accessibilityHint("Double tap to instantly log this amount")
    }

    private func triggerAnimation() {
        withAnimation(.easeOut(duration: 0.15)) {
            isAnimating = true
        }
        withAnimation(.easeIn(duration: 0.15).delay(0.15)) {
            isAnimating = false
        }
    }
}

// MARK: - Preview

#Preview {
    HStack {
        QuickAddPresetRow(
            preset: QuickAddPreset(trackerID: "protein", amount: 25, label: "Shake"),
            unit: "g"
        ) {}
        QuickAddPresetRow(
            preset: QuickAddPreset(trackerID: "water", amount: 16),
            unit: "fl oz"
        ) {}
    }
    .padding()
}
