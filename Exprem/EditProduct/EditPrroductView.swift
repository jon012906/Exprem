//
//  EditPrroductView.swift
//  Exprem
//
//  Created by Jon on 14/04/26.
//

import SwiftUI

enum EditReminderFrequency: String, CaseIterable {
    case daily = "Every Day"
    case weekly = "Every Week"
    case monthly = "Every Month"
    case yearly = "Every Year"
}

struct EditPrroductView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var expiryDate: Date
    @State private var note = ""
    @State private var startDate = Date()
    @State private var selectedFrequency: EditReminderFrequency = .weekly

    init(name: String, expiryDate: Date) {
        _name = State(initialValue: name)
        _expiryDate = State(initialValue: expiryDate)
    }

    var body: some View {
        List {
            Section {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.white.opacity(0.75))
                        .frame(height: 120)
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.gray.opacity(0.18), lineWidth: 0.8)
                        }

                    Text("Thumbnail")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                VStack(spacing: 10) {
                    TextField("Product Name", text: $name)
                        .font(.body)

                    Divider()

                    DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                }
                .padding(.vertical, 2)
            } header: {
                Text("Edit Product")
            }

            Section {
                DatePicker("Start Reminder", selection: $startDate, displayedComponents: .date)

                Menu {
                    ForEach(EditReminderFrequency.allCases, id: \.self) { frequency in
                        Button(frequency.rawValue) {
                            selectedFrequency = frequency
                        }
                    }
                } label: {
                    HStack {
                        Text("Frequency")
                        Spacer()
                        Text(selectedFrequency.rawValue)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Set Reminder")
            }

            Section {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.75))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 0.8)
                        }

                    TextField("Optional", text: $note)
                        .padding(12)
                }
            } header: {
                Text("Note")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.93, green: 0.93, blue: 0.95))
        .listSectionSpacing(14)
        .navigationTitle("Edit Product")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditPrroductView(name: "Milk", expiryDate: Date().addingTimeInterval(86400 * 3))
    }
}
