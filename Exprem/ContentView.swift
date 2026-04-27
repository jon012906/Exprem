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
    @State private var showSplash = true
    @State private var splashLogoScale: CGFloat = 0.9
    @State private var splashOpacity: Double = 0
    @State private var splashTextOffset: CGFloat = 8

    /// All products — used to reschedule notifications on launch.
    @Query private var products: [Product]

    private let scheduler = NotificationScheduler()

    var body: some View {
        ZStack {
            NavigationStack {
                DashboardView()
            }

            if showSplash {
                SplashView(
                    logoScale: splashLogoScale,
                    contentOpacity: splashOpacity,
                    textOffset: splashTextOffset
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .appTheme(colorScheme == .dark ? .dark : .light)
        .onAppear {
            requestNotificationPermissionIfNeeded()
            runSplashAnimationIfNeeded()
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

    private func runSplashAnimationIfNeeded() {
        guard showSplash else { return }

        withAnimation(.easeOut(duration: 0.35)) {
            splashOpacity = 1
            splashLogoScale = 1
            splashTextOffset = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            withAnimation(.easeInOut(duration: 0.25)) {
                splashOpacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                showSplash = false
            }
        }
    }
}

#Preview {
    ContentView()
}
