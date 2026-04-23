//
//  ScanFlowCoordinator.swift
//  Exprem
//
//  Created by Jon on 23/04/26.
//

import Foundation
import UIKit
import Observation

@Observable
@MainActor
final class ScanFlowCoordinator {
    var draft = ProductDraft()
    let session = ScanSessionState()

    func reset() {
        draft = ProductDraft()
        session.cleanup()
    }
}