//
//  NotificationScheduler.swift
//  Exprem
//
//  Created by Jon on 23/04/26.
//

import Foundation
import UserNotifications

/// Identifies which dashboard filter to open when a notification is tapped.
/// Raw value is stored in `userInfo["targetStatus"]` and read by the app delegate.
enum ItemStatus: String {
    case danger  = "danger"
    case warning = "warning"
    case safe    = "safe"
}

final class NotificationScheduler {
    private struct NotificationCandidate {
        let date: Date
        let product: Product
        let phase: Int
    }

    private struct NotificationGroup {
        let date: Date
        let phase: Int
        let products: [Product]
    }

    // Schedule notifications for ALL products.
    // Call this on every save or delete so content stays accurate.
    func scheduleAll(products: [Product]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        // Generate (fireDate, product, phase) tuples for all products
        var all: [NotificationCandidate] = []
        for product in products {
            all += fireDates(for: product)
        }

        // Priority: phase 4 > 3 > 2 > 1, then chronological
        all.sort {
            if $0.phase != $1.phase { return $0.phase > $1.phase }
            return $0.date < $1.date
        }

        let grouped = groupedNotifications(from: all)

        // Respect iOS 64-notification limit
        let capped = Array(grouped.prefix(64))

        for group in capped {
            schedule(group: group)
        }
    }

    // MARK: - Private

    private func fireDates(for product: Product) -> [NotificationCandidate] {
        let now = Date.now
        let expiry = product.expiryDate
        guard expiry > now else { return [] }  // Already expired — no notifs

        let reminderStart: Date = {
            let candidate = Calendar.current.date(
                byAdding: product.reminderUnit.calendarComponent,
                value: -product.reminderAmount,
                to: expiry
            ) ?? now
            return max(candidate, now)
        }()

        var results: [NotificationCandidate] = []

        func add(_ offset: Int, phase: Int) {
            guard let date = Calendar.current.date(byAdding: .day, value: offset, to: expiry),
                  date > reminderStart,
                  date > now else { return }
            results.append(NotificationCandidate(date: date, product: product, phase: phase))
        }

        // Phase 4 — days 7,6,4,2,1 before expiry
        for offset in [-7, -6, -4, -2, -1] { add(offset, phase: 4) }

        // Phase 3 — days 14,11,8 before expiry
        for offset in [-14, -11, -8] { add(offset, phase: 3) }

        // Phase 2 — every 7 days in 15–30 day window
        var cursor = Calendar.current.date(byAdding: .day, value: -30, to: expiry) ?? now
        let phase2End = Calendar.current.date(byAdding: .day, value: -15, to: expiry) ?? now
        cursor = max(cursor, reminderStart)
        while cursor <= phase2End {
            if cursor > now { results.append(NotificationCandidate(date: cursor, product: product, phase: 2)) }
            cursor = Calendar.current.date(byAdding: .day, value: 7, to: cursor) ?? phase2End.addingTimeInterval(1)
        }

        // Phase 1 — every 14 days before 31-day window
        let phase1End = Calendar.current.date(byAdding: .day, value: -31, to: expiry) ?? now
        cursor = reminderStart
        while cursor <= phase1End {
            if cursor > now { results.append(NotificationCandidate(date: cursor, product: product, phase: 1)) }
            cursor = Calendar.current.date(byAdding: .day, value: 14, to: cursor) ?? phase1End.addingTimeInterval(1)
        }

        return results
    }

    private func groupedNotifications(from candidates: [NotificationCandidate]) -> [NotificationGroup] {
        var grouped: [String: NotificationGroup] = [:]
        let calendar = Calendar.current

        for candidate in candidates {
            let day = calendar.startOfDay(for: candidate.date)
            let key: String
            if candidate.phase == 4 {
                key = "\(candidate.phase)-\(day.timeIntervalSince1970)-\(candidate.product.id.uuidString)"
            } else {
                key = "\(candidate.phase)-\(day.timeIntervalSince1970)"
            }

            if var existing = grouped[key] {
                existing = NotificationGroup(
                    date: existing.date,
                    phase: existing.phase,
                    products: existing.products + [candidate.product]
                )
                grouped[key] = existing
            } else {
                grouped[key] = NotificationGroup(
                    date: candidate.date,
                    phase: candidate.phase,
                    products: [candidate.product]
                )
            }
        }

        return grouped.values.sorted {
            if $0.phase != $1.phase { return $0.phase > $1.phase }
            return $0.date < $1.date
        }
    }

    private func schedule(group: NotificationGroup) {
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.threadIdentifier = "expiry"
        let productCount = group.products.count
        let primaryProduct = group.products
            .sorted { $0.expiryDate < $1.expiryDate }
            .first

        let titleBody: (title: String, body: String)
        let targetStatus: ItemStatus = .danger

        switch group.phase {
        case 4:
            if productCount == 1, let primaryProduct {
                titleBody = (
                    "Expiring Soon!",
                    "\(primaryProduct.nameProduct) will be expired. Check it now!"
                )
            } else {
                titleBody = (
                    "Expiring Soon!",
                    "There are \(productCount) products will be expired. Check it now!"
                )
            }
        case 3:
            if productCount == 1, let primaryProduct {
                titleBody = (
                    "Expiring Soon!",
                    "\(primaryProduct.nameProduct) will be expired. Check it now!"
                )
            } else {
                titleBody = (
                    "Expiring Soon!",
                    "There are \(productCount) products will be expired. Check it now!"
                )
            }
        case 2:
            titleBody = (
                "Expiring Soon!",
                "There are \(productCount) products will be expired. Check it now!"
            )
        default:
            titleBody = (
                "Expiring Soon!",
                "There are \(productCount) products will be expired. Check it now!"
            )
        }

        content.title = titleBody.title
        content.body = titleBody.body
        content.userInfo["targetStatus"] = targetStatus.rawValue
        if group.phase == 4, let primaryProduct {
            content.userInfo["targetProductID"] = primaryProduct.id.uuidString
        }

        var components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: group.date
        )
        components.hour = 9   // fire at 09:00 on that day
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let id = "phase\(group.phase)-\(Calendar.current.startOfDay(for: group.date).timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
