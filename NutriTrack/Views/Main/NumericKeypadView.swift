import SwiftUI

// MARK: - NumericKeypadView

struct NumericKeypadView: View {
    @Binding var inputText: String
    let onSubmit: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    private let keys: [[KeypadKey]] = [
        [.digit("1"), .digit("2"), .digit("3")],
        [.digit("4"), .digit("5"), .digit("6")],
        [.digit("7"), .digit("8"), .digit("9")],
        [.decimal, .digit("0"), .backspace]
    ]

    var body: some View {
        VStack(spacing: 8) {
            // Display
            Text(inputText.isEmpty ? "0" : inputText)
                .font(Typography.keypadDisplay)
                .foregroundStyle(Color(.label))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .contentTransition(.numericText())

            // Keys grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(keys.flatMap { $0 }) { key in
                    KeypadButton(key: key) {
                        handleKey(key)
                    }
                }
            }

            // Action row
            HStack(spacing: 12) {
                Button(action: { inputText = "" }) {
                    Text("Clear")
                        .font(Typography.label)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .foregroundStyle(Color(.label))
                .accessibilityLabel("Clear input")

                Button(action: onSubmit) {
                    Text("Log")
                        .font(Typography.sfPro(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .foregroundStyle(.white)
                .disabled(inputText.isEmpty || Double(inputText) == nil || Double(inputText) == 0)
                .accessibilityLabel("Log entry")
                .accessibilityHint("Double tap to log the entered amount")
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Key handling

    private func handleKey(_ key: KeypadKey) {
        switch key {
        case .digit(let d):
            appendDigit(d)
        case .decimal:
            appendDecimal()
        case .backspace:
            if !inputText.isEmpty {
                inputText.removeLast()
            }
        }
    }

    private func appendDigit(_ digit: String) {
        // Prevent leading zeros
        if inputText == "0" {
            inputText = digit
            return
        }
        // Max 1 decimal place
        if let dotIdx = inputText.firstIndex(of: ".") {
            let decimals = inputText.distance(from: dotIdx, to: inputText.endIndex) - 1
            if decimals >= 1 { return }
        }
        // Max total length
        if inputText.replacingOccurrences(of: ".", with: "").count >= 6 { return }
        inputText += digit
    }

    private func appendDecimal() {
        guard !inputText.contains(".") else { return }
        if inputText.isEmpty { inputText = "0" }
        inputText += "."
    }
}

// MARK: - KeypadKey

private enum KeypadKey: Identifiable, Hashable {
    case digit(String)
    case decimal
    case backspace

    var id: String {
        switch self {
        case .digit(let d): return "digit_\(d)"
        case .decimal: return "decimal"
        case .backspace: return "backspace"
        }
    }

    var displayText: String? {
        switch self {
        case .digit(let d): return d
        case .decimal: return "."
        case .backspace: return nil
        }
    }
}

// MARK: - KeypadButton

private struct KeypadButton: View {
    let key: KeypadKey
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)

                if let text = key.displayText {
                    Text(text)
                        .font(Typography.keypadDigit)
                        .foregroundStyle(Color(.label))
                } else {
                    Image(systemName: "delete.left.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color(.label))
                }
            }
            .frame(height: 52)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.93 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(accessibilityLabel)
    }

    private var backgroundColor: Color {
        switch key {
        case .backspace: return Color(.tertiarySystemBackground)
        default: return Color(.secondarySystemBackground)
        }
    }

    private var accessibilityLabel: String {
        switch key {
        case .digit(let d): return d
        case .decimal: return "decimal point"
        case .backspace: return "backspace"
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var input = "42.5"
    NumericKeypadView(inputText: $input) {
        print("Submitted: \(input)")
    }
    .padding()
}
