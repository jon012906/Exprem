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
    
    var body: some View {
        VStack{
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
                        HStack(spacing: 8) {
                            TextField("Product Name", text: $name)
                                .font(.body)

                            Button {
                                showScanName = true
                            } label: {
                                Image(systemName: "camera.viewfinder")
                                    .font(.headline)
                                    .foregroundStyle(.blue)
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
                                    .foregroundStyle(.blue)
                            }
                            
                        }
                    }
                    .padding(.vertical, 2)
                } header: {
                    Text("Add Product")
                }
                
                Section {
                    DatePicker("Start Reminder", selection: $startDate, displayedComponents: .date)
                    
                    Button {
                        showFrequencySheet = true
                    }
                    label: {
                        HStack {
                            Text("Frequency")
                            Spacer()
                            Text(selectedFrequency.rawValue)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                header: {
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button{
                        dismiss()
                    } label: {
                        GlassBackButton()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        NotificationCenter.default.post(name: .returnToDashboard, object: nil)
                        dismiss()
                    }.buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .font(.headline.weight(.semibold))
                        
                }
            }
            .sheet(isPresented: $showFrequencySheet) {
                FrequencyPickerView(selected: $selectedFrequency)
            }
            .navigationDestination(isPresented: $showScanName) {
                ScanProductNameView(origin: .addProduct)
            }
            .navigationDestination(isPresented: $showScanExpiry) {
                ScanProductExpiryView(origin: .addProduct)
            }
        }.navigationBarBackButtonHidden(true)
        
    }
}



#Preview {
    NavigationStack {
        AddProductView()
    }
//    AddProductView()
}
