//
//  EditPrroductView.swift
//  Exprem
//
//  Created by Jon on 14/04/26.
//

import SwiftUI
import SwiftData
import UIKit

struct EditPrroductView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    let product: Product

    @State private var name: String
    @State private var expiryDate: Date
    @State private var note: String
    @State private var startDate: Date
    @State private var reminderAmount = 1
    @State private var selectedFrequency: ReminderFrequency = .weekly
    @State private var showFrequencySheet = false

    init(product: Product) {
        self.product = product
        _name = State(initialValue: product.nameProduct)
        _expiryDate = State(initialValue: product.expiryDate)
        _note = State(initialValue: product.note)
        _startDate = State(initialValue: product.reminderStartDate ?? Date())
    }

    var body: some View {
        List {
            
            //MARK: PRODUCT INFORMATION
            Section {
                HStack{
                    Spacer()
                    ZStack {
                        Image(.dummy)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                    }
                    Spacer()
                }
            }

            //MARK: SCHEDULE REMINDER
            Section {
                VStack(spacing: 10) {
                    HStack{
                        Text("Product Name")
                                .foregroundColor(theme.appPlaceholder)
                        
                        Spacer()
                        
                        TextField("Name", text: $name)
                                .font(.body)
                                .multilineTextAlignment(.trailing)
                    }

                    Divider()

                    DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                        .tint(theme.appBlue)
                        .foregroundStyle(theme.appPlaceholder)
                }
                .padding(.vertical, 2)
            } header: {
                Text("Product Information")
            }
            
            //MARK: SCHEDULE REMINDER
            Section {
                DatePicker("Start Reminder", selection: $startDate, displayedComponents: .date)
                    .foregroundStyle(theme.appPlaceholder)

                Button {
                    showFrequencySheet = true
                } label: {
                    HStack {
                        Text("Every").foregroundStyle(theme.appPlaceholder)
                        Spacer()
                        Text("\(reminderAmount) \(selectedFrequency.rawValue)")
                            .foregroundColor(theme.appTextSecondary)
                    }
                }
            } header: {
                Text("Schedule Reminder")
            }

            Section {
                ZStack {
                    TextField("Optional", text: $note)
                }
                Divider()
            } header: {
                Text("Note")
            }
        }
        .scrollContentBackground(.hidden)
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
                    product.nameProduct = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    product.expiryDate = expiryDate
                    product.note = note
                    product.reminderStartDate = startDate
                    product.updatedAt = Date()
                    try? modelContext.save()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.appBlue)
                .foregroundStyle(.white)
            }
        }
        .sheet(isPresented: $showFrequencySheet) {
            FrequencyPickerView(amount: $reminderAmount, selected: $selectedFrequency)
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
                .appTheme(theme)
        }
    }
}

#Preview {
    NavigationStack {
        EditPrroductView(product: Product(nameProduct: "Milk", expiryDate: Date().addingTimeInterval(86400 * 3)))
    }
}
