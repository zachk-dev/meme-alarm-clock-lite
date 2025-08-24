//
//  AlarmStore.swift
//  MemeAlarmLite
//
//  Created by Zach on 2025-08-22.
//

import Foundation
import UserNotifications

struct AlarmItem: Identifiable, Hashable {
    let id: String                 // request.identifier
    let title: String
    let body: String
    let soundName: String?
    let repeats: Bool
    let nextFire: Date?
    let groupId: String?           // from content.threadIdentifier (optional)
}

final class AlarmStore: ObservableObject {
    @Published var alarms: [AlarmItem] = []

    func refresh() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
            let items: [AlarmItem] = reqs.map { req in
                let content = req.content
                let soundName: String?
                if case let .some(unSound) = content.sound,
                   let sel = Mirror(reflecting: unSound).children
                        .first(where: { $0.label == "name" })?.value as? String {
                    soundName = sel
                } else {
                    soundName = nil
                }

                var repeats = false
                var next: Date? = nil
                if let trig = req.trigger as? UNCalendarNotificationTrigger {
                    repeats = trig.repeats
                    next = trig.nextTriggerDate()
                }

                return AlarmItem(
                    id: req.identifier,
                    title: content.title,
                    body: content.body,
                    soundName: soundName,
                    repeats: repeats,
                    nextFire: next,
                    groupId: content.threadIdentifier.isEmpty ? nil : content.threadIdentifier
                )
            }
            // Sort: soonest first
            let sorted = items.sorted { (a, b) in
                switch (a.nextFire, b.nextFire) {
                case let (.some(x), .some(y)): return x < y
                case (.some, .none): return true
                case (.none, .some): return false
                default: return a.title < b.title
                }
            }
            DispatchQueue.main.async { self.alarms = sorted }
        }
    }

    func cancel(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        refresh()
    }

    // Optional helper: cancel an entire group (same threadIdentifier)
    func cancelGroup(groupId: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
            let ids = reqs.filter { $0.content.threadIdentifier == groupId }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
            self.refresh()
        }
    }
}
