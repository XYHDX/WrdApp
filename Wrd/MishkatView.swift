import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// The mishkāt — the illuminated record. Light is never taken away.
struct MishkatView: View {
    @Environment(WrdStore.self) private var store
    @State private var selectedDayKey: DayKey?

    private var hijriCalendar: Calendar {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = Locale(identifier: "ar")
        return calendar
    }

    /// The dates of the current hijri month, paired with their lit state.
    private var monthDays: [(day: Int, date: Date, isToday: Bool)] {
        let calendar = hijriCalendar
        let now = Date()
        guard let range = calendar.range(of: .day, in: .month, for: now) else { return [] }
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        let todayDay = components.day ?? 1
        return range.compactMap { day in
            guard let date = calendar.date(from: DateComponents(calendar: calendar,
                                                                year: components.year,
                                                                month: components.month,
                                                                day: day)) else { return nil }
            return (day, date, day == todayDay)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("\(HijriDate.currentMonth()) · نورُ الشهر")
                        .font(.caption)
                        .foregroundStyle(WrdColor.muted)
                    lampField
                    stats
                    khatmaNote
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(WrdColor.ground.ignoresSafeArea())
            .scrollIndicators(.hidden)
            .navigationTitle("المشكاة")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    shareButton
                }
            }
            .sheet(item: $selectedDayKey) { day in
                DayDetailView(dayKey: day.id)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    @ViewBuilder
    private var shareButton: some View {
        #if canImport(UIKit)
        if let image = renderShareImage() {
            ShareLink(item: image,
                      preview: SharePreview("مشكاتي — \(HijriDate.currentMonth())", image: image)) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(WrdColor.gold)
            }
        } else {
            textShare
        }
        #else
        textShare
        #endif
    }

    private var textShare: some View {
        ShareLink(item: "وِردُكَ نُورُك — \(arabicNumber(store.litDaysAllTime)) يومًا مضيئًا في مشكاتي 🕯 تطبيق وِرْد") {
            Image(systemName: "square.and.arrow.up")
                .foregroundStyle(WrdColor.gold)
        }
    }

    #if canImport(UIKit)
    @MainActor
    private func renderShareImage() -> Image? {
        let flags = monthDays.map { store.isLit(dayKey: WrdStore.key(for: $0.date)) }
        let card = MishkatShareCard(monthName: HijriDate.currentMonth(), litFlags: flags)
            .environment(\.layoutDirection, .rightToLeft)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        guard let ui = renderer.uiImage else { return nil }
        return Image(uiImage: ui)
    }
    #endif

    private var lampField: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(monthDays, id: \.day) { entry in
                    lamp(isLit: store.isLit(dayKey: WrdStore.key(for: entry.date)),
                         isToday: entry.isToday)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDayKey = DayKey(id: WrdStore.key(for: entry.date))
                        }
                }
            }
            Text("كل مصباحٍ يومٌ أتممتَ فيه أورادك — النور لا يُنتزع أبدًا")
                .font(.caption2)
                .foregroundStyle(WrdColor.faint)
        }
        .padding(18)
        .wrdWash()
    }

    private func lamp(isLit: Bool, isToday: Bool) -> some View {
        Circle()
            .fill(isLit ? WrdColor.gold : WrdColor.washStrong)
            .frame(width: isLit ? 12 : 9, height: isLit ? 12 : 9)
            .frame(width: 34, height: 34)
            .background(Circle().fill(isLit ? WrdColor.goldWash : Color.clear))
            .overlay(
                Circle()
                    .stroke(isToday ? WrdColor.gold : Color.clear, lineWidth: 1.5)
            )
            .shadow(color: isLit ? WrdColor.gold.opacity(0.5) : Color.clear, radius: 6)
    }

    private var stats: some View {
        HStack(spacing: 10) {
            stat(arabicNumber(store.litDaysAllTime), "يومٌ مضيء")
            stat(arabicNumber(store.totalCompletedAllTime), "وِردٌ أُتمّ")
            stat(arabicNumber(store.awrad.count), "وِردٌ محفوظ")
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.weight(.semibold))
                .foregroundStyle(WrdColor.gold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(WrdColor.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .wrdWash(cornerRadius: 18)
    }

    private var khatmaNote: some View {
        HStack(spacing: 12) {
            Image(systemName: "seal")
                .foregroundStyle(WrdColor.goldDeep)
            Text("شموس الختمات تُذهَّب هنا مع حلقات الختمة — قريبًا بإذن الله")
                .font(.caption)
                .foregroundStyle(WrdColor.muted)
            Spacer()
        }
        .padding(14)
        .wrdWash(cornerRadius: 16)
    }
}

// MARK: - Day detail

struct DayKey: Identifiable {
    let id: String
}

struct DayDetailView: View {
    @Environment(WrdStore.self) private var store
    let dayKey: String

    private var record: DayRecord? { store.days[dayKey] }

    private var completedTitles: [String] {
        guard let record else { return [] }
        return store.awrad.filter { record.isDone($0) }.map(\.title)
    }

    private var dateTitle: String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: dayKey) else { return dayKey }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.locale = Locale(identifier: "ar")
        formatter.dateFormat = "EEEE، d MMMM y"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(dateTitle)
                .font(.headline)
                .padding(.top, 22)
            if store.isLit(dayKey: dayKey) {
                Label("يومٌ مضيء — اكتملت الأوراد", systemImage: "sparkles")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(WrdColor.gold)
            } else if completedTitles.isEmpty {
                Text("لا أوراد مسجّلة في هذا اليوم")
                    .font(.subheadline)
                    .foregroundStyle(WrdColor.muted)
            } else {
                Text("أُتمّ فيه \(arabicNumber(completedTitles.count)) وِردًا")
                    .font(.subheadline)
                    .foregroundStyle(WrdColor.muted)
            }
            if !completedTitles.isEmpty {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(completedTitles, id: \.self) { title in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(WrdColor.gold)
                                Text(title)
                                    .font(.subheadline)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .wrdWash(cornerRadius: 12)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WrdColor.ground.ignoresSafeArea())
        .environment(\.layoutDirection, .rightToLeft)
    }
}

// MARK: - Shareable render — the month as an illuminated card

struct MishkatShareCard: View {
    let monthName: String
    let litFlags: [Bool]

    private let ground = Color(hexValue: 0x1D1710)
    private let gold = Color(hexValue: 0xD6B25E)
    private let goldDeep = Color(hexValue: 0xB08D36)
    private let parchmentText = Color(hexValue: 0xF0E6D2)
    private let mutedText = Color(hexValue: 0xA79878)

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 4) {
                Text("مشكاتي")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(parchmentText)
                Text(monthName)
                    .font(.subheadline)
                    .foregroundStyle(mutedText)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(litFlags.indices, id: \.self) { index in
                    Circle()
                        .fill(litFlags[index] ? gold : Color(hexValue: 0x54401F, alpha: 0.45))
                        .frame(width: litFlags[index] ? 13 : 9, height: litFlags[index] ? 13 : 9)
                        .frame(width: 30, height: 30)
                        .shadow(color: litFlags[index] ? gold.opacity(0.6) : .clear, radius: 5)
                }
            }
            .padding(.horizontal, 8)
            VStack(spacing: 3) {
                Text("\(arabicNumber(litFlags.filter { $0 }.count)) يومًا مضيئًا")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(gold)
                Text("وِردُكَ نُورُك — تطبيق وِرْد")
                    .font(.caption)
                    .foregroundStyle(goldDeep)
            }
        }
        .padding(28)
        .frame(width: 390)
        .background(ground)
    }
}

#Preview {
    MishkatView()
        .environment(WrdStore())
        .environment(\.layoutDirection, .rightToLeft)
}
