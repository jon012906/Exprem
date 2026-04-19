//
//  AddProductView.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//

import SwiftUI

enum ReminderFrequency: String, CaseIterable {
    case daily = "Day"
    case weekly = "Week"
    case monthly = "Month"
    case yearly = "Year"
}

struct AddProductView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = "Name"
    @State private var expiryDate = Date()
    @State private var note = ""
    
    @State private var startDate = Date()
    @State private var reminderAmount = 1
    @State private var selectedFrequency: ReminderFrequency = .weekly
    @State private var showFrequencySheet = false
    @State private var showScanName = false
    @State private var showScanExpiry = false
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        VStack{
            List {
                //MARK: THUMBNAIL
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
                
                //MARK: PRODUCT INFORMATION
                Section {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Product Name")
                                    .foregroundColor(theme.appPlaceholder)
                                
                                Spacer()
                            
                                TextField("Name", text: $name)
                                    .font(.body)
                                    .multilineTextAlignment(.trailing)
//                                    .frame(width: 115) // control width
                                    
                                
                                Button {
                                    showScanName = true
                                } label: {
                                    Image(systemName: "camera.viewfinder")
                                        .font(.headline)
                                        .foregroundStyle(theme.appBlue)
                                }
                        }

                        Divider()

                        HStack(spacing: 8) {
                            DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date).foregroundStyle(theme.appPlaceholder)
                            
                            Button {
                                showScanExpiry = true
                            } label: {
                                Image(systemName: "camera.viewfinder")
                                    .font(.headline)
                                    .foregroundStyle(theme.appBlue)
                            }
                            
                        }
                    }
                    .padding(.vertical, 2)
                } header: {
                    Text("Product Information")
                }
                
                //MARK: SCHEDULE REMINDER
                Section {
                    DatePicker("Start Reminder", selection: $startDate, displayedComponents: .date).foregroundStyle(theme.appPlaceholder)
                    
                    Button {
                        showFrequencySheet = true
                    } label: {
                        HStack {
                            Text("Every").foregroundColor(theme.appPlaceholder)
                            Spacer()
                            Text("\(reminderAmount) \(selectedFrequency.rawValue)")
                                .foregroundColor(theme.appTextSecondary)
                        }
                    }
                }
                header: {
                    Text("Schedule Reminder")
                }
                
                //MARK: NOTE
                Section {
                    ZStack {
                        TextField("Optional", text: $note)
                    }
                    Divider()
                }
                header: {
                    Text("Note")
                }
            }
            .scrollContentBackground(.hidden)
            .listSectionSpacing(14)
            .navigationTitle("Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        NotificationCenter.default.post(name: .returnToDashboard, object: nil)
                        dismiss()
                    }.buttonStyle(.borderedProminent)
                        .tint(theme.appBlue)
                        .font(.headline.weight(.semibold))
                        
                }
            }
            .navigationDestination(isPresented: $showScanName) {
                ScanProductNameView(origin: .addProduct)
            }
            .navigationDestination(isPresented: $showScanExpiry) {
                ScanProductExpiryView(origin: .addProduct)
            }
            .sheet(isPresented: $showFrequencySheet) {
                FrequencyPickerView(amount: $reminderAmount, selected: $selectedFrequency)
                    .presentationDetents([.height(320)])
                    .presentationDragIndicator(.visible)
                    .appTheme(theme)
            }
        }
    }
}



#Preview {
    NavigationStack {
        AddProductView()
    }
}
