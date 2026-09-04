import Foundation

/// The four gates of WRD — التوقيتات.
enum Gate: String, CaseIterable, Identifiable, Codable {
    case morning, afterPrayer, night, general
    var id: String { rawValue }

    var arabicTitle: String {
        switch self {
        case .morning: return "الوِرد الصباحي"
        case .afterPrayer: return "أوراد ما بعد الصلاة"
        case .night: return "الوِرد الليلي"
        case .general: return "أوراد الأحوال"
        }
    }

    var subtitle: String {
        switch self {
        case .morning: return "بعد الفجر حتى الشروق"
        case .afterPrayer: return "بعد كل صلاة"
        case .night: return "المساء وقبل النوم"
        case .general: return "أذكار المواقف اليومية"
        }
    }

    var symbol: String {
        switch self {
        case .morning: return "sun.and.horizon"
        case .afterPrayer: return "hands.sparkles"
        case .night: return "moon.stars"
        case .general: return "sparkles"
        }
    }
}

/// A wird — one committed unit of devotion.
struct Wird: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var text: String?          // the dhikr/duʿā' text, if any
    var source: String?        // e.g. "رواه مسلم" — every duʿā' shows its source
    var gate: Gate
    var targetCount: Int = 1   // 1 = read once / check off; >1 = counter
    var isCustom: Bool = false // written by the user
    var note: String?          // optional personal dedication/intention
    var reminderMinutes: Int?  // optional daily reminder, minutes from midnight
}

/// Formats minutes-from-midnight as an Arabic clock time, e.g. "٦:٣٠".
func minutesTimeString(_ minutes: Int) -> String {
    let start = Calendar.current.startOfDay(for: Date())
    let date = Calendar.current.date(byAdding: .minute, value: minutes, to: start) ?? start
    return prayerTimeString(date)
}

/// One day's completion record.
struct DayRecord: Codable {
    var completed: [UUID: Int] = [:]   // wird id → count reached

    func isDone(_ wird: Wird) -> Bool {
        (completed[wird.id] ?? 0) >= wird.targetCount
    }
}

extension Gate {
    /// The gate that matters right now — a time heuristic until the prayer engine lands.
    static var current: Gate {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 4..<11: return .morning
        case 11..<17: return .afterPrayer
        default: return .night
        }
    }
}

// MARK: - Khatma circles — حلقات الختمة

struct KhatmaMember: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var assigned: [Int] = []        // juz' numbers 1...30
    var completed: Set<Int> = []
}

struct KhatmaCircle: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var dedication: String?
    var members: [KhatmaMember] = []
    var createdAt: Date = Date()
    /// nil = created on this device (creator). false = joined via an invite code.
    var createdHere: Bool?
    /// In a joined circle: which member is *me* — only that member's ajzā' are editable.
    var myMemberID: UUID?

    var isCreator: Bool { createdHere ?? true }
    var completedCount: Int { members.reduce(0) { $0 + $1.completed.count } }
    var progress: Double { Double(completedCount) / 30.0 }
    var isComplete: Bool { completedCount >= 30 }

    func canEdit(_ member: KhatmaMember) -> Bool {
        isCreator || member.id == myMemberID
    }
}

enum HijriDate {
    /// Today as an Umm al-Qura hijri date, in Arabic.
    static func today() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.locale = Locale(identifier: "ar")
        formatter.dateFormat = "EEEE، d MMMM y"
        return formatter.string(from: Date())
    }

    /// Current hijri month name + year, in Arabic (e.g. "رمضان ١٤٤٨").
    static func currentMonth() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.locale = Locale(identifier: "ar")
        formatter.dateFormat = "MMMM y"
        return formatter.string(from: Date())
    }
}

/// Arabic-Indic digits for counts and stats.
func arabicNumber(_ value: Int) -> String {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "ar")
    return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
}
