//
//  AppDelegate.swift
//  MemeAlarmLite
//
//  Created by Zach on 2025-08-21.
//


import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        registerCategories()

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, err in
            if let err = err { print("Auth error:", err) }
            print("Notifications granted:", granted)
        }
        return true
    }

    private func registerCategories() {
        let snooze5 = UNNotificationAction(identifier: "SNOOZE_5", title: "Snooze 5 min", options: [])
        let stop = UNNotificationAction(identifier: "STOP", title: "Stop", options: [.destructive])

        let alarmCategory = UNNotificationCategory(
            identifier: "ALARM_MEME",
            actions: [snooze5, stop],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
    }

    // Show banner + sound even if app is foregrounded
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // Handle Snooze/Stop
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let req = response.notification.request

        switch response.actionIdentifier {
        case "SNOOZE_5":
            let content = (req.content.mutableCopy() as! UNMutableNotificationContent)
            // Use same title/body/sound/category
            let fire = Date().addingTimeInterval(5 * 60)
            let comps = Calendar.current.dateComponents([.hour, .minute, .second, .day, .month, .year], from: fire)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let newId = "snooze-\(UUID().uuidString)"
            center.add(UNNotificationRequest(identifier: newId, content: content, trigger: trigger))

        case "STOP", UNNotificationDismissActionIdentifier, UNNotificationDefaultActionIdentifier:
            break

        default: break
        }
        completionHandler()
    }
}
