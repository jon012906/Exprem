//
//  ExpremApp.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//

import SwiftUI
import SwiftData

@main
struct ExpremApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Product.self])
    }
}
