import Foundation

/// On-device prayer time calculation — standard solar astronomy, fully offline.
/// Default angles: Muslim World League (Fajr 18°, Isha 17°), Shafi'i asr.
/// City-based (no location permission needed); GPS can come later.

struct City: Identifiable, Codable, Hashable {
    var id: String { name }
    let name: String
    let arabicName: String
    let latitude: Double
    let longitude: Double

    static let all: [City] = [
        City(name: "Damascus", arabicName: "دمشق", latitude: 33.5138, longitude: 36.2765),
        City(name: "Aleppo", arabicName: "حلب", latitude: 36.2021, longitude: 37.1343),
        City(name: "Homs", arabicName: "حمص", latitude: 34.7324, longitude: 36.7137),
        City(name: "Amman", arabicName: "عمّان", latitude: 31.9539, longitude: 35.9106),
        City(name: "Beirut", arabicName: "بيروت", latitude: 33.8938, longitude: 35.5018),
        City(name: "Cairo", arabicName: "القاهرة", latitude: 30.0444, longitude: 31.2357),
        City(name: "Makkah", arabicName: "مكة المكرمة", latitude: 21.4225, longitude: 39.8262),
        City(name: "Madinah", arabicName: "المدينة المنورة", latitude: 24.4672, longitude: 39.6111),
        City(name: "Riyadh", arabicName: "الرياض", latitude: 24.7136, longitude: 46.6753),
        City(name: "Jeddah", arabicName: "جدة", latitude: 21.4858, longitude: 39.1925),
        City(name: "Dubai", arabicName: "دبي", latitude: 25.2048, longitude: 55.2708),
        City(name: "Kuwait City", arabicName: "الكويت", latitude: 29.3759, longitude: 47.9774),
        City(name: "Doha", arabicName: "الدوحة", latitude: 25.2854, longitude: 51.5310),
        City(name: "Baghdad", arabicName: "بغداد", latitude: 33.3152, longitude: 44.3661),
        City(name: "Istanbul", arabicName: "إسطنبول", latitude: 41.0082, longitude: 28.9784),
        City(name: "London", arabicName: "لندن", latitude: 51.5074, longitude: -0.1278),
    ]

    static let `default` = all[0] // Damascus
}

enum PrayerName: String, CaseIterable, Identifiable {
    case fajr, sunrise, dhuhr, asr, maghrib, isha
    var id: String { rawValue }

    var arabicName: String {
        switch self {
        case .fajr: return "الفجر"
        case .sunrise: return "الشروق"
        case .dhuhr: return "الظهر"
        case .asr: return "العصر"
        case .maghrib: return "المغرب"
        case .isha: return "العشاء"
        }
    }
}

struct DayPrayers {
    let times: [PrayerName: Date]

    func time(_ prayer: PrayerName) -> Date? { times[prayer] }

    /// The next prayer (excluding sunrise) after the given moment, if any remain today.
    func nextPrayer(after date: Date = Date()) -> (PrayerName, Date)? {
        let order: [PrayerName] = [.fajr, .dhuhr, .asr, .maghrib, .isha]
        for prayer in order {
            if let t = times[prayer], t > date { return (prayer, t) }
        }
        return nil
    }
}

enum PrayerCalculator {

    /// Calculates the day's prayer times for a coordinate, in the device's time zone.
    static func times(for date: Date = Date(),
                      latitude: Double,
                      longitude: Double,
                      timeZone: TimeZone = .current) -> DayPrayers {

        let calendar = Calendar(identifier: .gregorian)
        var comps = calendar.dateComponents(in: timeZone, from: date)
        comps.hour = 12; comps.minute = 0; comps.second = 0

        let year = comps.year!, month = comps.month!, day = comps.day!
        let jd = julianDay(year: year, month: month, day: day)
        let (declination, eqOfTime) = solar(jd: jd)

        let tzHours = Double(timeZone.secondsFromGMT(for: date)) / 3600.0
        let dhuhrHours = 12.0 + tzHours - longitude / 15.0 - eqOfTime

        func hourAngle(_ angle: Double) -> Double? {
            let latR = radians(latitude), decR = radians(declination)
            let cosH = (-sinDeg(angle) - sin(latR) * sin(decR)) / (cos(latR) * cos(decR))
            guard cosH >= -1, cosH <= 1 else { return nil }
            return degrees(acos(cosH)) / 15.0
        }

        // Asr (Shafi'i: shadow = object + noon shadow)
        func asrHourAngle() -> Double? {
            let latR = radians(latitude), decR = radians(declination)
            let angle = atan(1.0 / (1.0 + tan(abs(latR - decR))))
            let cosH = (sin(angle) - sin(latR) * sin(decR)) / (cos(latR) * cos(decR))
            guard cosH >= -1, cosH <= 1 else { return nil }
            return degrees(acos(cosH)) / 15.0
        }

        let fajrAngle = 18.0, ishaAngle = 17.0, horizon = 0.833

        var result: [PrayerName: Date] = [:]
        func setTime(_ prayer: PrayerName, _ hours: Double?) {
            guard let hours else { return }
            let startOfDay = calendar.date(from: DateComponents(timeZone: timeZone, year: year, month: month, day: day))!
            let seconds = hours * 3600.0
            result[prayer] = startOfDay.addingTimeInterval(seconds)
        }

        setTime(.dhuhr, dhuhrHours + 2.0/60.0)
        if let ha = hourAngle(fajrAngle) { setTime(.fajr, dhuhrHours - ha) }
        if let ha = hourAngle(horizon) {
            setTime(.sunrise, dhuhrHours - ha)
            setTime(.maghrib, dhuhrHours + ha + 2.0/60.0)
        }
        if let ha = hourAngle(ishaAngle) { setTime(.isha, dhuhrHours + ha) }
        if let ha = asrHourAngle() { setTime(.asr, dhuhrHours + ha) }

        return DayPrayers(times: result)
    }

    // MARK: Solar position

    private static func julianDay(year: Int, month: Int, day: Int) -> Double {
        var y = Double(year), m = Double(month)
        if m <= 2 { y -= 1; m += 12 }
        let a = floor(y / 100.0)
        let b = 2 - a + floor(a / 4.0)
        return floor(365.25 * (y + 4716)) + floor(30.6001 * (m + 1)) + Double(day) + b - 1524.5
    }

    /// Returns (declination in degrees, equation of time in hours) at solar noon.
    private static func solar(jd: Double) -> (Double, Double) {
        let d = jd - 2451545.0
        let g = normalize(357.529 + 0.98560028 * d)          // mean anomaly
        let q = normalize(280.459 + 0.98564736 * d)          // mean longitude
        let l = normalize(q + 1.915 * sinDeg(g) + 0.020 * sinDeg(2 * g)) // ecliptic longitude
        let e = 23.439 - 0.00000036 * d                      // obliquity

        let declination = degrees(asin(sinDeg(e) * sinDeg(l)))
        var ra = degrees(atan2(cosDeg(e) * sinDeg(l), cosDeg(l))) / 15.0
        ra = ra.truncatingRemainder(dividingBy: 24); if ra < 0 { ra += 24 }
        var eqt = q / 15.0 - ra
        if eqt > 12 { eqt -= 24 }; if eqt < -12 { eqt += 24 }
        return (declination, eqt)
    }

    private static func normalize(_ deg: Double) -> Double {
        var d = deg.truncatingRemainder(dividingBy: 360); if d < 0 { d += 360 }; return d
    }
    private static func radians(_ deg: Double) -> Double { deg * .pi / 180 }
    private static func degrees(_ rad: Double) -> Double { rad * 180 / .pi }
    private static func sinDeg(_ d: Double) -> Double { sin(radians(d)) }
    private static func cosDeg(_ d: Double) -> Double { cos(radians(d)) }
}

/// Formats a prayer time in Arabic digits, e.g. "٥:١٢".
func prayerTimeString(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ar")
    formatter.dateFormat = "h:mm"
    return formatter.string(from: date)
}
