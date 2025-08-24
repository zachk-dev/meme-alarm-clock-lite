//
//  ContentView.swift
//  MemeAlarmLite
//
//  Created by Zach on 2025-08-21.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    @State private var time = roundToNextMinute(Date().addingTimeInterval(60)) // default: 1 min ahead
    @State private var selectedSound = "shrek-hello-there.caf"   // must exist in bundle
    @State private var repeatsDaily = true
    @State private var extraRings = 2                     // additional notifications 1 min apart
    private let availableSounds = ["shrek-hello-there.caf", "fun-song.caf", "wilhelm.caf"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Time") {
                    DatePicker("Alarm Time", selection: $time, displayedComponents: .hourAndMinute)
                    Toggle("Repeat Daily", isOn: $repeatsDaily)
                }

                Section("Sound") {
                    Picker("Meme Sound", selection: $selectedSound) {
                        ForEach(availableSounds, id: \.self) { Text($0) }
                    }
                }

                Section("Behavior") {
                    Stepper("Extra rings: \(extraRings)", value: $extraRings, in: 0...4)
                    Text("Tip: extra rings are scheduled as separate notifications 1 minute apart.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Schedule Alarm") { scheduleAlarm() }
                    Button("List Pending in Console") { debugList() }
                        .foregroundStyle(.secondary)
                    Button("Cancel All") {
                        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    }
                    .tint(.red)
                }
            }
            .navigationTitle("Meme Alarm (Lite)")
        }
    }

    private func scheduleAlarm() {
        let center = UNUserNotificationCenter.current()

        // Base content
        let content = UNMutableNotificationContent()
        content.title = "🌅 Rise & Meme"
        content.body = "Time to greet the day with chaos."
        content.categoryIdentifier = "ALARM_MEME"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: selectedSound))

        if repeatsDaily {
            // Repeat every day at chosen hour:minute (system handles DST/timezones)
            let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let id = "alarm-\(UUID().uuidString)"
            let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(req) { if let e = $0 { print("Schedule error:", e) } }

            // Optional: daily extra rings 1 and 2 minutes later (also repeating)
            for i in 1...extraRings {
                var c = DateComponents()
                c.hour = comps.hour
                c.minute = (comps.minute ?? 0 + i) % 60
                // Note: if minute rolls over, hour may shift by system rules; it's fine for a simple "extra ping"
                let trig = UNCalendarNotificationTrigger(dateMatching: c, repeats: true)
                let rid = "alarm-extra-\(i)-\(UUID().uuidString)"
                center.add(UNNotificationRequest(identifier: rid, content: content, trigger: trig))
            }

        } else {
            // One-off alarm (tomorrow if the time already passed today)
            var fire = Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: time),
                                             minute: Calendar.current.component(.minute, from: time),
                                             second: 0, of: Date())!
            if fire <= Date() { fire = Calendar.current.date(byAdding: .day, value: 1, to: fire)! }

            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fire)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let id = "alarm-once-\(UUID().uuidString)"
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))

            for i in 1...extraRings {
                let extra = fire.addingTimeInterval(TimeInterval(60 * i))
                let ce = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: extra)
                let trig = UNCalendarNotificationTrigger(dateMatching: ce, repeats: false)
                let rid = "alarm-once-extra-\(i)-\(UUID().uuidString)"
                center.add(UNNotificationRequest(identifier: rid, content: content, trigger: trig))
            }
        }
    }

    private func debugList() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
            print("Pending:", reqs.map { $0.identifier })
        }
    }

    static func roundToNextMinute(_ date: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date.addingTimeInterval(60))
        return cal.date(from: comps) ?? date.addingTimeInterval(60)
    }
}

private func roundToNextMinute(_ date: Date) -> Date { ContentView.roundToNextMinute(date) }
