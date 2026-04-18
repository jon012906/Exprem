//
//  AddProductView.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//

import SwiftUI

enum ReminderFrequency: String, CaseIterable {
    case daily = "Every Day"
    case weekly = "Every Week"
    case monthly = "Every Month"
    case yearly = "Every Year"
}

struct AddProductView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var expiryDate = Date()
    @State private var note = ""
    
    @State private var startDate = Date()
    @State private var selectedFrequency: ReminderFrequency = .weekly
    @State private var showFrequencySheet = false
    @State private var showScanName = false
    @State private var showScanExpiry = false
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        VStack{
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
                        HStack(spacing: 8) {
                            TextField("Product Name", text: $name)
                                .font(.body)
                            
                            Spacer()
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
                            DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                            
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
                    Text("Add Product")
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
                            Text("Frequency").foregroundColor(theme.appTextPrimary)
                            Spacer()
                            Text(selectedFrequency.rawValue)
                                .foregroundColor(theme.appTextSecondary)
                        }
                    }
                }
                header: {
                    Text("Set Reminder")
                }
                
                Section {
                    ZStack {
                        TextField("Optional", text: $note)
                    }
                }
                header: {
                    Text("Note")
                }
            }
            .scrollContentBackground(.hidden)
//            .background(Color(red: 0.93, green: 0.93, blue: 0.95))
            .listSectionSpacing(14)
            .navigationTitle("Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button{
//                        dismiss()
//                    } label: {
//                        GlassBackButton()
//                    }
//                }
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
        }
//        .navigationBarBackButtonHidden(true)
        
    }
}



#Preview {
    NavigationStack {
        AddProductView()
    }
}
