//
//  ContentView.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//

import SwiftUI
import SwiftData
import UserNotifications

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    /// All products — used to reschedule notifications on launch.
    @Query private var products: [Product]

    private let scheduler = NotificationScheduler()

    var body: some View {
        NavigationStack {
            DashboardView()
        }
        .appTheme(colorScheme == .dark ? .dark : .light)
        .onAppear {
            requestNotificationPermissionIfNeeded()
        }
    }

    // MARK: - Private

    /// Requests permission once, then (re)schedules all notifications so
    /// the pending set is always up-to-date even after the app was killed.
    private func requestNotificationPermissionIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                scheduler.scheduleAll(products: products)
            }
        }
    }
}

#Preview {
    ContentView()
}
