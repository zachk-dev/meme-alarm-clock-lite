//
//  ScheduledAlarmsView.swift
//  MemeAlarmLite
//
//  Created by Zach on 2025-08-22.
//

import SwiftUI

struct ScheduledAlarmsView: View {
    @StateObject var store = AlarmStore()
    private let df: DateFormatter = {
        let d = DateFormatter()
        d.dateStyle = .none
        d.timeStyle = .short
        return d
    }()

    var body: some View {
        List {
            if store.alarms.isEmpty {
                ContentUnavailableView("No scheduled alarms",
                                       systemImage: "alarm",
                                       description: Text("Tap “Schedule Alarm” on the main screen."))
            } else {
                ForEach(store.alarms) { alarm in
                    HStack(spacing: 12) {
                        Image(systemName: alarm.repeats ? "repeat" : "calendar")
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(alarm.title.isEmpty ? "Alarm" : alarm.title)
                                .font(.headline)
                            HStack(spacing: 8) {
                                if let t = alarm.nextFire {
                                    Text(df.string(from: t))
                                } else {
                                    Text("time pending")
                                }
                                if alarm.repeats { Text("• repeats").foregroundStyle(.secondary) }
                                if let s = alarm.soundName { Text("• \(s)").foregroundStyle(.secondary) }
                            }
                            .font(.subheadline)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            store.cancel(id: alarm.id)
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
        .navigationTitle("Scheduled Alarms")
        .onAppear { store.refresh() }
        .refreshable { store.refresh() }
    }
}
