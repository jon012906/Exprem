//
//  AddProductView.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//

import SwiftUI
import SwiftData
import UIKit

struct AddProductView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    /// All existing products — needed to reschedule all notifications on save.
    @Query private var products: [Product]

    @State private var draft: ProductDraft

    @State private var name: String
    @State private var expiryDate: Date
    @State private var note: String

    @State private var startDate: Date
    @State private var reminderAmount: Int
    @State private var selectedFrequency: ReminderFrequency
    @State private var showFrequencySheet = false
    @State private var showScanName = false
    @State private var showScanExpiry = false

    private let scheduler = NotificationScheduler()

    init(draft: ProductDraft = ProductDraft()) {
        _draft = State(initialValue: draft)
        _name = State(initialValue: draft.nameProduct)
        _expiryDate = State(initialValue: draft.expiryDate)
        _note = State(initialValue: draft.note)
        _startDate = State(initialValue: draft.reminderStartDate ?? Date())
        _reminderAmount = State(initialValue: draft.reminderAmount)
        _selectedFrequency = State(initialValue: draft.reminderUnit)
    }

    var body: some View {
        VStack {
            List {
                //MARK: THUMBNAIL
                Section {
                    HStack {
                        Spacer()
                        ZStack {
                            if let thumbnailImage {
                                Image(uiImage: thumbnailImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            } else {
                                Image(systemName: "cart")
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
                            DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                                .foregroundStyle(theme.appPlaceholder)

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
                    DatePicker("Start Reminder", selection: $startDate, displayedComponents: .date)
                        .foregroundStyle(theme.appPlaceholder)

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
                } header: {
                    Text("Schedule Reminder")
                }

                //MARK: NOTE
                Section {
                    ZStack {
                        TextField("Optional", text: $note)
                    }
                } header: {
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
                        saveProduct()
                    }
                    .buttonStyle(.borderedProminent)
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
                reminderAmount = newDraft.reminderAmount
                selectedFrequency = newDraft.reminderUnit
            }
        }
    }

    // MARK: - Private

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
        draft.reminderAmount = reminderAmount
        draft.reminderUnit = selectedFrequency
    }

    private func saveProduct() {
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = cleanedName.isEmpty ? "Untitled Product" : cleanedName

        let savedThumbnailFilename: String?
        if let thumbnailData = draft.thumbnailData {
            print("[DEBUG] thumbnailData exists, saving to file...")
            savedThumbnailFilename = ProductImageStore.saveThumbnail(from: thumbnailData)
            print("[DEBUG] savedThumbnailFilename: \(savedThumbnailFilename ?? "nil")")
        } else {
            print("[DEBUG] No thumbnailData, using draft.thumbnailPath: \(draft.thumbnailPath ?? "nil")")
            savedThumbnailFilename = draft.thumbnailPath
        }

        let product = Product(
            nameProduct: finalName,
            expiryDate: expiryDate,
            note: note,
            reminderStartDate: startDate,
            reminderAmount: reminderAmount,
            reminderUnit: selectedFrequency,
            thumbnailPath: savedThumbnailFilename,
            updatedAt: Date()
        )

        print("[DEBUG] Inserting product: \(product.nameProduct), id: \(product.id)")
        modelContext.insert(product)
        
        do {
            try modelContext.save()
            print("[DEBUG] Save SUCCESS!")
        } catch {
            print("[DEBUG] Save FAILED: \(error)")
        }

        // Reschedule notifications for all products including the new one
        scheduler.scheduleAll(products: products + [product])

        NotificationCenter.default.post(name: .returnToDashboard, object: nil)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        AddProductView()
    }
}
