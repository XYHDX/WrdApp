import Foundation
import UserNotifications

/// The reminder engine v2 — anchored to real, on-device prayer times.
/// Calm by design: one call per prayer, gate reminders after Fajr and ʿIshā',
/// scheduled two days ahead and refreshed whenever the app opens.
enum NotificationManager {

    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func reschedule(store: WrdStore) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard store.remindersEnabled else { return }

        let calendar = Calendar.current
        let now = Date()

        for dayOffset in 0...1 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let prayers = PrayerCalculator.times(for: day,
                                                 latitude: store.city.latitude,
                                                 longitude: store.city.longitude)

            // The call at each prayer — الأذان كتنبيه
            if store.adhanEnabled {
                for prayer in [PrayerName.fajr, .dhuhr, .asr, .maghrib, .isha] {
                    guard let time = prayers.time(prayer), time > now else { continue }
                    schedule(center: center,
                             at: time,
                             id: "wrd.adhan.\(prayer.rawValue).\(dayOffset)",
                             title: "حان وقتُ صلاة \(prayer.arabicName) 🕌",
                             body: "\(prayerTimeString(time)) في \(store.city.arabicName) — ولا تنسَ وِردَ ما بعد الصلاة")
                }
            }

            // Gate reminders anchored to the day's real times
            if let fajr = prayers.time(.fajr) {
                let time = fajr.addingTimeInterval(20 * 60)
                if time > now {
                    schedule(center: center, at: time,
                             id: "wrd.morning.\(dayOffset)",
                             title: "وِردُ الصباح ينتظرك",
                             body: "أذكار الصباح ووِردك من القرآن — أضِئ يومك")
                }
            }
            if let isha = prayers.time(.isha) {
                let time = isha.addingTimeInterval(30 * 60)
                if time > now {
                    schedule(center: center, at: time,
                             id: "wrd.night.\(dayOffset)",
                             title: "أنِر ليلتك بوِردك",
                             body: "أذكار النوم وسورة الملك من مصحفك")
                }
            }
        }

        // Per-wird reminders at the user's chosen time — daily, repeating.
        for wird in store.awrad {
            guard let minutes = wird.reminderMinutes else { continue }
            let content = UNMutableNotificationContent()
            content.title = "وِردك: \(wird.title)"
            content.body = "حان الموعدُ الذي اخترتَه — أضِئ وِردك"
            content.sound = .default
            var components = DateComponents()
            components.hour = minutes / 60
            components.minute = minutes % 60
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            center.add(UNNotificationRequest(identifier: "wrd.wird.\(wird.id.uuidString)",
                                             content: content, trigger: trigger))
        }
    }

    private static func schedule(center: UNUserNotificationCenter,
                                 at date: Date, id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                         from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
