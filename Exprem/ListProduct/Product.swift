//
// Product.swift
// Exprem
//
// Created by Jon on 12/04/26.

import Foundation
import SwiftData

@Model
final class Product {
    var id: UUID
    var nameProduct: String
    var expiryDate: Date
    var note: String
    var reminderStartDate: Date?
    /// How many units before expiry reminders should begin.
    var reminderAmount: Int
    /// The unit of time for the reminder interval (day / week / month / year).
    var reminderUnit: ReminderFrequency
    var thumbnailPath: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        nameProduct: String,
        expiryDate: Date,
        note: String = "",
        reminderStartDate: Date? = nil,
        reminderAmount: Int = 1,
        reminderUnit: ReminderFrequency = .weekly,
        thumbnailPath: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.nameProduct = nameProduct
        self.expiryDate = expiryDate
        self.note = note
        self.reminderStartDate = reminderStartDate
        self.reminderAmount = reminderAmount
        self.reminderUnit = reminderUnit
        self.thumbnailPath = thumbnailPath
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
