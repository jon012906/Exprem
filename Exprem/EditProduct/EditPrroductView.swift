//
//  EditPrroductView.swift
//  Exprem
//
//  Created by Jon on 14/04/26.
//

import SwiftUI

//enum ReminderFrequency: String, CaseIterable {
//    case daily = "Every Day"
//    case weekly = "Every Week"
//    case monthly = "Every Month"
//    case yearly = "Every Year"
//}

struct EditPrroductView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var expiryDate: Date
    @State private var note = ""
    @State private var startDate = Date()
    @State private var selectedFrequency: ReminderFrequency = .weekly

    init(name: String, expiryDate: Date) {
        _name = State(initialValue: name)
        _expiryDate = State(initialValue: expiryDate)
    }

    var body: some View {
        List {
            Section {
                ZStack {
                    Image(.dummy)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                }
            }

            Section {
                VStack(spacing: 10) {
                    TextField("Product Name", text: $name)
                        .font(.body)

                    Divider()

                    DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date).tint(.blue)
                }
                .padding(.vertical, 2)
            } header: {
                Text("Edit Product")
            }

            Section {
                DatePicker("Start Reminder", selection: $startDate, displayedComponents: .date)

                Menu {
                    ForEach(ReminderFrequency.allCases, id: \.self) { frequency in
                        Button(frequency.rawValue) {
                            selectedFrequency = frequency
                        }
                    }
                } label: {
                    HStack {
                        Text("Frequency").foregroundColor(.primary)
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
                    TextField("Optional", text: $note)
                }
            } header: {
                Text("Note")
            }
        }
        .scrollContentBackground(.hidden)
//        .background(Color(red: 0.93, green: 0.93, blue: 0.95))
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
                }.buttonStyle(.borderedProminent).foregroundStyle(.white)
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditPrroductView(name: "Milk", expiryDate: Date().addingTimeInterval(86400 * 3))
    }
}
