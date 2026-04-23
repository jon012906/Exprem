//
// ReminderFrequency.swift
// Exprem
//
// Created by Jon on 23/04/26.
//

import Foundation

/// The unit of time a user picks for their reminder interval.
enum ReminderFrequency: String, CaseIterable, Codable {
    case daily   = "Day"
    case weekly  = "Week"
    case monthly = "Month"
    case yearly  = "Year"

    /// Maps to the matching `Calendar.Component` for date arithmetic.
    var calendarComponent: Calendar.Component {
        switch self {
        case .daily:   return .day
        case .weekly:  return .weekOfYear
        case .monthly: return .month
        case .yearly:  return .year
        }
    }
}
