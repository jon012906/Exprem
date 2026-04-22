//
//  AddProductView.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//

import SwiftUI
import SwiftData
import UIKit

enum ReminderFrequency: String, CaseIterable {
    case daily = "Day"
    case weekly = "Week"
    case monthly = "Month"
    case yearly = "Year"
}

struct AddProductView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    @State private var draft: ProductDraft
    
    @State private var name: String
    @State private var expiryDate: Date
    @State private var note: String
    
    @State private var startDate: Date
    @State private var reminderAmount = 1
    @State private var selectedFrequency: ReminderFrequency = .weekly
    @State private var showFrequencySheet = false
    @State private var showScanName = false
    @State private var showScanExpiry = false

    init(draft: ProductDraft = ProductDraft()) {
        _draft = State(initialValue: draft)
        _name = State(initialValue: draft.nameProduct)
        _expiryDate = State(initialValue: draft.expiryDate)
        _note = State(initialValue: draft.note)
        _startDate = State(initialValue: draft.reminderStartDate ?? Date())
    }
    
    var body: some View {
        VStack{
            List {
                //MARK: THUMBNAIL
                Section {
                    HStack{
                        Spacer()
                        ZStack {
                            if let thumbnailImage {
                                Image(uiImage: thumbnailImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            } else {
                                Image(.dummy)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 120)
                            }
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
                                
                                Button {
                                    syncDraftFromForm()
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
                                syncDraftFromForm()
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
                        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let finalName = cleanedName.isEmpty ? "Untitled Product" : cleanedName

                        let savedThumbnailFilename: String?
                        if let thumbnailData = draft.thumbnailData {
                            savedThumbnailFilename = ProductImageStore.saveThumbnail(from: thumbnailData)
                        } else {
                            savedThumbnailFilename = draft.thumbnailPath
                        }

                        let product = Product(
                            nameProduct: finalName,
                            expiryDate: expiryDate,
                            note: note,
                            reminderStartDate: startDate,
                            thumbnailPath: savedThumbnailFilename,
                            updatedAt: Date()
                        )

                        modelContext.insert(product)
                        try? modelContext.save()
                        NotificationCenter.default.post(name: .returnToDashboard, object: nil)
                        dismiss()
                    }.buttonStyle(.borderedProminent)
                        .tint(theme.appBlue)
                        .font(.headline.weight(.semibold))
                        
                }
            }
            .navigationDestination(isPresented: $showScanName) {
                ScanProductNameView(origin: .addProduct, draft: $draft)
            }
            .navigationDestination(isPresented: $showScanExpiry) {
                ScanProductExpiryView(origin: .addProduct, draft: $draft)
            }
            .sheet(isPresented: $showFrequencySheet) {
                FrequencyPickerView(amount: $reminderAmount, selected: $selectedFrequency)
                    .presentationDetents([.height(320)])
                    .presentationDragIndicator(.visible)
                    .appTheme(theme)
            }
            .onChange(of: draft) { _, newDraft in
                if !newDraft.nameProduct.isEmpty {
                    name = newDraft.nameProduct
                }
                expiryDate = newDraft.expiryDate
                note = newDraft.note
                startDate = newDraft.reminderStartDate ?? startDate
            }
        }
    }

    private var thumbnailImage: UIImage? {
        if let data = draft.thumbnailData {
            return UIImage(data: data)
        }
        return ProductImageStore.loadImage(filename: draft.thumbnailPath)
    }

    private func syncDraftFromForm() {
        draft.nameProduct = name
        draft.expiryDate = expiryDate
        draft.note = note
        draft.reminderStartDate = startDate
    }
}



#Preview {
    NavigationStack {
        AddProductView()
    }
}
