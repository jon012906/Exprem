//
// ScanFlowOrigin.swift
// Exprem
//
// Created by Jon on 14/04/26.

import Foundation

enum ScanFlowOrigin: Equatable {
    case onboarding
    case addProduct
}

extension Notification.Name {
    static let returnToDashboard = Notification.Name("returnToDashboard")
}
