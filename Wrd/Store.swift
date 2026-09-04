import Foundation
import Observation
import UIKit

/// In-app appearance — the founder's rule: parchment by day, candlelight by night, user in control.
enum WrdTheme: String, CaseIterable, Identifiable {
    case auto, parchment, candlelight
    var id: String { rawValue }

    var arabicTitle: String {
        switch self {
        case .auto: return "تلقائي"
        case .parchment: return "المصحف (فاتح)"
        case .candlelight: return "القنديل (داكن)"
        }
    }
}

/// The single source of truth: the user's awrād, day records, and settings.
/// Persisted as JSON in Application Support. (SwiftData/CloudKit sync comes later.)
@Observable
final class WrdStore {

    // MARK: State
    var awrad: [Wird] = []
    var days: [String: DayRecord] = [:]
    var circles: [KhatmaCircle] = []

    // MARK: Settings (UserDefaults-backed)
    var theme: WrdTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "wrd.theme") }
    }
    var morningReminderMinutes: Int {
        didSet { UserDefaults.standard.set(morningReminderMinutes, forKey: "wrd.reminder.morning") }
    }
    var nightReminderMinutes: Int {
        didSet { UserDefaults.standard.set(nightReminderMinutes, forKey: "wrd.reminder.night") }
    }
    var remindersEnabled: Bool {
        didSet { UserDefaults.standard.set(remindersEnabled, forKey: "wrd.reminder.enabled") }
    }
    var adhanEnabled: Bool {
        didSet { UserDefaults.standard.set(adhanEnabled, forKey: "wrd.adhan.enabled") }
    }
    var city: City {
        didSet { UserDefaults.standard.set(city.name, forKey: "wrd.city") }
    }
    var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: "wrd.user.name") }
    }
    var largeText: Bool {
        didSet { UserDefaults.standard.set(largeText, forKey: "wrd.largeText") }
    }
    var hasOnboarded: Bool {
        didSet { UserDefaults.standard.set(hasOnboarded, forKey: "wrd.onboarded") }
    }

    // MARK: Init

    init() {
        let defaults = UserDefaults.standard
        theme = WrdTheme(rawValue: defaults.string(forKey: "wrd.theme") ?? "") ?? .auto
        morningReminderMinutes = defaults.object(forKey: "wrd.reminder.morning") as? Int ?? 5 * 60 + 30
        nightReminderMinutes = defaults.object(forKey: "wrd.reminder.night") as? Int ?? 21 * 60 + 30
        remindersEnabled = defaults.object(forKey: "wrd.reminder.enabled") as? Bool ?? false
        adhanEnabled = defaults.object(forKey: "wrd.adhan.enabled") as? Bool ?? true
        let cityName = defaults.string(forKey: "wrd.city") ?? City.default.name
        city = City.all.first { $0.name == cityName } ?? City.default
        userName = defaults.string(forKey: "wrd.user.name") ?? ""
        largeText = defaults.object(forKey: "wrd.largeText") as? Bool ?? false
        hasOnboarded = defaults.object(forKey: "wrd.onboarded") as? Bool ?? false
        load()
        startDayRollover()
        // The user starts with an empty, personal space — awrād are chosen,
        // never imposed. المكتبة is one tap away, and "الأوراد المقترحة" is optional.
    }

    // MARK: Day keys

    static func key(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: Day rollover — the day flips when the clock flips to 00:00

    /// Today's key as observable state: when it changes at midnight,
    /// every view reading `today` re-renders for the new day.
    private(set) var dayKey: String = WrdStore.key()

    @ObservationIgnored private var midnightTimer: Timer?
    @ObservationIgnored private var timeChangeObserver: NSObjectProtocol?

    private func startDayRollover() {
        // Fires when the system day changes, or the clock/timezone is adjusted.
        timeChangeObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.significantTimeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshDayIfNeeded()
        }
        scheduleMidnightTimer()
    }

    /// Rolls `dayKey` forward if the calendar day changed. Safe to call often.
    func refreshDayIfNeeded() {
        let key = Self.key()
        if key != dayKey {
            dayKey = key
        }
        scheduleMidnightTimer()
    }

    /// One-shot timer at the exact next 00:00 (+1s cushion), rescheduled daily.
    private func scheduleMidnightTimer() {
        midnightTimer?.invalidate()
        guard let nextMidnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) else { return }
        let timer = Timer(fire: nextMidnight.addingTimeInterval(1), interval: 0, repeats: false) { [weak self] _ in
            self?.refreshDayIfNeeded()
        }
        timer.tolerance = 0.5
        RunLoop.main.add(timer, forMode: .common)
        midnightTimer = timer
    }

    deinit {
        midnightTimer?.invalidate()
        if let observer = timeChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    var today: DayRecord {
        days[dayKey] ?? DayRecord()
    }

    // MARK: Prayer times

    var todayPrayers: DayPrayers {
        PrayerCalculator.times(latitude: city.latitude, longitude: city.longitude)
    }

    /// The founder's ordering rule: morning leads until it is finished; then the
    /// after-prayer awrād lead; after ʿIshā' the night wird leads. Finished gates sink.
    func gateOrder() -> [Gate] {
        let now = Date()
        let prayers = todayPrayers
        let hour = Calendar.current.component(.hour, from: now)
        let isNight: Bool = {
            if let isha = prayers.time(.isha) { return now >= isha }
            return hour >= 19 || hour < 4
        }()

        var order: [Gate]
        if isNight {
            order = [.night, .afterPrayer, .morning]
        } else if progress(of: .morning) >= 1 {
            order = [.afterPrayer, .morning, .night]
        } else {
            order = [.morning, .afterPrayer, .night]
        }
        let unfinished = order.filter { progress(of: $0) < 1 || awrad(in: $0).isEmpty }
        let finished = order.filter { progress(of: $0) >= 1 && !awrad(in: $0).isEmpty }
        return unfinished + finished
    }

    /// Re-adds any missing starter awrād (after deletions) — nothing is duplicated.
    func restoreStarters() {
        for wird in AdhkarLibrary.starterAwrad where !contains(wird) {
            awrad.append(wird)
        }
        save()
    }

    /// Adds a library wird into a gate the user chose.
    func add(_ wird: Wird, to gate: Gate) {
        var copy = wird
        copy.gate = gate
        guard !contains(copy) else { return }
        awrad.append(copy)
        save()
    }

    // MARK: Queries

    func awrad(in gate: Gate) -> [Wird] {
        awrad.filter { $0.gate == gate }
    }

    func count(for wird: Wird) -> Int {
        today.completed[wird.id] ?? 0
    }

    func isDone(_ wird: Wird) -> Bool {
        today.isDone(wird)
    }

    func progress(of gate: Gate) -> Double {
        let items = awrad(in: gate)
        guard !items.isEmpty else { return 0 }
        let done = items.filter { isDone($0) }.count
        return Double(done) / Double(items.count)
    }

    /// A day is "lit" when every wird of the three timed gates is complete.
    func isLit(dayKey: String) -> Bool {
        guard let record = days[dayKey] else { return false }
        let timed = awrad.filter { $0.gate != .general }
        guard !timed.isEmpty else { return false }
        return timed.allSatisfy { record.isDone($0) }
    }

    var todayIsLit: Bool { isLit(dayKey: dayKey) }

    var totalCompletedAllTime: Int {
        days.values.reduce(0) { total, record in
            total + record.completed.filter { id, count in
                if let wird = awrad.first(where: { $0.id == id }) {
                    return count >= wird.targetCount
                }
                return count > 0
            }.count
        }
    }

    var litDaysAllTime: Int {
        days.keys.filter { isLit(dayKey: $0) }.count
    }

    // MARK: Mutations — light is never taken away

    func setCount(_ count: Int, for wird: Wird) {
        var record = today
        let previous = record.completed[wird.id] ?? 0
        record.completed[wird.id] = max(previous, count)   // never decreases
        days[dayKey] = record
        save()
    }

    func markDone(_ wird: Wird) {
        setCount(wird.targetCount, for: wird)
    }

    /// Undo a mistaken tap — clears TODAY's progress for this wird only.
    /// Past days are history and stay lit; only the current day is editable.
    func resetToday(_ wird: Wird) {
        var record = today
        record.completed[wird.id] = 0
        days[dayKey] = record
        save()
    }

    func add(_ wird: Wird) {
        guard !awrad.contains(where: { $0.id == wird.id }) else { return }
        awrad.append(wird)
        save()
    }

    func contains(_ wird: Wird) -> Bool {
        awrad.contains(where: { $0.id == wird.id })
    }

    func remove(_ wird: Wird) {
        awrad.removeAll { $0.id == wird.id }
        save()
    }

    // MARK: Khatma circles

    func add(_ circle: KhatmaCircle) {
        circles.append(circle)
        save()
    }

    func update(_ circle: KhatmaCircle) {
        if let index = circles.firstIndex(where: { $0.id == circle.id }) {
            circles[index] = circle
            save()
        }
    }

    func removeCircle(_ circle: KhatmaCircle) {
        circles.removeAll { $0.id == circle.id }
        save()
    }

    /// Allocates the 30 ajzā' as sequential ranges by the creator's chosen counts.
    /// counts must sum to 30; names and counts are parallel.
    static func allocateAjza(names: [String], counts: [Int]) -> [KhatmaMember] {
        var members: [KhatmaMember] = []
        var next = 1
        for (index, name) in names.enumerated() {
            let count = counts[index]
            guard count > 0 else { members.append(KhatmaMember(name: name)); continue }
            members.append(KhatmaMember(name: name, assigned: Array(next..<(next + count))))
            next += count
        }
        return members
    }

    /// Even split of 30 for n members (remainder to the first members).
    static func evenCounts(for memberCount: Int) -> [Int] {
        guard memberCount > 0 else { return [] }
        let base = 30 / memberCount
        let remainder = 30 % memberCount
        return (0..<memberCount).map { $0 < remainder ? base + 1 : base }
    }

    /// Merges a pasted circle or progress code. Returns a human message.
    func merge(_ decoded: CircleCodec.Decoded) -> String {
        switch decoded {
        case .circle(let incoming):
            if circles.contains(where: { $0.id == incoming.id }) {
                return "هذه الحلقة موجودة عندك بالفعل"
            }
            circles.append(incoming)
            save()
            return "انضممتَ إلى حلقة «\(incoming.name)» — حدّد اسمك من داخل الحلقة"
        case .progress(let update):
            guard let circleIndex = circles.firstIndex(where: { $0.id == update.circleID }) else {
                return "لم أجد هذه الحلقة على جهازك"
            }
            guard let memberIndex = circles[circleIndex].members.firstIndex(where: { $0.id == update.memberID }) else {
                return "لم أجد هذا العضو في الحلقة"
            }
            circles[circleIndex].members[memberIndex].completed = Set(update.completed)
            save()
            return "تحدّث تقدم \(update.memberName) — ما شاء الله"
        }
    }

    // MARK: Persistence

    private struct Persisted: Codable {
        var awrad: [Wird]
        var days: [String: DayRecord]
        var circles: [KhatmaCircle]?
    }

    private static var fileURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("wrd-state.json")
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.fileURL),
              let state = try? JSONDecoder().decode(Persisted.self, from: data) else { return }
        awrad = state.awrad
        days = state.days
        circles = state.circles ?? []
    }

    func save() {
        let state = Persisted(awrad: awrad, days: days, circles: circles)
        if let data = try? JSONEncoder().encode(state) {
            try? data.write(to: Self.fileURL, options: .atomic)
        }
    }
}
