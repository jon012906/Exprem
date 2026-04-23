//
// ProductDraft.swift
// Exprem
//
// Created by Jon on 22/04/26.

import Foundation

struct ProductDraft: Equatable {
    var nameProduct: String
    var expiryDate: Date
    var note: String
    var reminderStartDate: Date?
    var reminderAmount: Int
    var reminderUnit: ReminderFrequency
    var thumbnailPath: String?
    var thumbnailData: Data?

    init(
        nameProduct: String = "",
        expiryDate: Date = Date(),
        note: String = "",
        reminderStartDate: Date? = Date(),
        reminderAmount: Int = 1,
        reminderUnit: ReminderFrequency = .weekly,
        thumbnailPath: String? = nil,
        thumbnailData: Data? = nil
    ) {
        self.nameProduct = nameProduct
        self.expiryDate = expiryDate
        self.note = note
        self.reminderStartDate = reminderStartDate
        self.reminderAmount = reminderAmount
        self.reminderUnit = reminderUnit
        self.thumbnailPath = thumbnailPath
        self.thumbnailData = thumbnailData
    }

    init(product: Product) {
        self.nameProduct = product.nameProduct
        self.expiryDate = product.expiryDate
        self.note = product.note
        self.reminderStartDate = product.reminderStartDate
        self.reminderAmount = product.reminderAmount
        self.reminderUnit = product.reminderUnit
        self.thumbnailPath = product.thumbnailPath
        self.thumbnailData = nil
    }
}
