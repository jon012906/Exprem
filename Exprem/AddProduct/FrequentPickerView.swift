import SwiftUI

struct FrequencyPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selected: ReminderFrequency

    var body: some View {
        NavigationStack {
            List {
                ForEach(ReminderFrequency.allCases, id: \.self) { freq in
                    HStack {
                        Text(freq.rawValue)
                        Spacer()
                        if freq == selected {
                            Image(systemName: "checkmark")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selected = freq
                        dismiss()
                    }
                }
            }
            .navigationTitle("Reminder Frequency")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
