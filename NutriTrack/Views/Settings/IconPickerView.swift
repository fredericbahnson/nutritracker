import SwiftUI

// MARK: - IconPickerView

struct IconPickerView: View {
    let selectedIconName: String?
    let onSelect: (String?) -> Void

    @Environment(\.dismiss) private var dismiss

    private let categories = ["Nutrition", "Activity", "Wellness", "General"]

    var body: some View {
        NavigationStack {
            List {
                // "No icon" — show tracker name as label
                Button {
                    onSelect(nil)
                    dismiss()
                } label: {
                    HStack {
                        Text("Label (no icon)")
                        Spacer()
                        if selectedIconName == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color(.label))
                        }
                    }
                }
                .foregroundStyle(Color(.label))

                ForEach(categories, id: \.self) { category in
                    let icons = TrackerIconLibrary.all.filter { $0.category == category }
                    Section(header: Text(category)) {
                        ForEach(icons) { icon in
                            Button {
                                onSelect(icon.id)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    TrackerIconLibrary.iconView(
                                        for: icon, size: 24,
                                        color: Color(.secondaryLabel)
                                    )
                                    Text(icon.displayName)
                                    Spacer()
                                    if selectedIconName == icon.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color(.label))
                                    }
                                }
                            }
                            .foregroundStyle(Color(.label))
                        }
                    }
                }
            }
            .navigationTitle(Text("Choose Icon"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    IconPickerView(selectedIconName: "dna") { _ in }
}
