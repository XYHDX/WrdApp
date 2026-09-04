import SwiftUI

/// اليوم — one screen. Gates ordered by the founder's rule: morning leads until
/// finished, then after-prayer, and after ʿIshā' the night wird leads.
struct TodayView: View {
    @Environment(WrdStore.self) private var store
    @State private var activeWird: Wird?
    @State private var openGate: Gate?
    @State private var showSettings = false
    @State private var showSuggested = false

    var body: some View {
        NavigationStack {
            let order = store.gateOrder()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    headerRow
                    heroCard(order[0])
                    HStack(spacing: 12) {
                        ForEach(order.dropFirst()) { gate in
                            compactTile(gate)
                        }
                    }
                    generalRow
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .safeAreaInset(edge: .bottom) {
                Text("هذا التطبيق مجانيٌّ تمامًا — وتكفينا دعوةٌ صادقةٌ من قلبك لمؤسسه يحيى ضميرية 🤍")
                    .font(.caption2)
                    .foregroundStyle(WrdColor.faint)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .background(WrdColor.ground)
            }
            .background(WrdColor.ground.ignoresSafeArea())
            .navigationTitle("اليوم")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(WrdColor.muted)
                    }
                }
            }
        }
        .sheet(item: $activeWird) { wird in CounterView(wird: wird) }
        .sheet(item: $openGate) { gate in GateDetailView(gate: gate) }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showSuggested) { SuggestedAwradView() }
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                if !store.userName.isEmpty {
                    Text("حيّاك الله يا \(store.userName) 🤍")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(WrdColor.gold)
                }
                Text(HijriDate.today())
                    .font(.subheadline)
                    .foregroundStyle(WrdColor.muted)
            }
            Spacer()
            if store.todayIsLit {
                Label("أُضيءَ اليوم", systemImage: "sparkles")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(WrdColor.gold)
            } else if let (prayer, time) = store.todayPrayers.nextPrayer() {
                Text("\(prayer.arabicName) \(prayerTimeString(time))")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(WrdColor.goldDeep)
            }
        }
    }

    // MARK: Hero — the leading gate

    private func heroCard(_ gate: Gate) -> some View {
        let items = store.awrad(in: gate)
        let preview = Array(items.prefix(3))
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                GateRing(progress: store.progress(of: gate), size: 62)
                VStack(alignment: .leading, spacing: 3) {
                    Text(gate.arabicTitle)
                        .font(.title2.weight(.semibold))
                    Text(gate.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(WrdColor.muted)
                }
                Spacer()
                Image(systemName: "chevron.backward")
                    .font(.subheadline)
                    .foregroundStyle(WrdColor.faint)
            }
            if items.isEmpty {
                emptyGateHint
            } else {
                VStack(spacing: 7) {
                    ForEach(preview) { wird in
                        heroRow(wird)
                    }
                }
                if items.count > preview.count {
                    Text("و\(arabicNumber(items.count - preview.count)) أخرى — انقر للمزيد")
                        .font(.footnote)
                        .foregroundStyle(WrdColor.faint)
                }
            }
        }
        .padding(16)
        .wrdWash()
        .shadow(color: Color.black.opacity(0.07), radius: 16, y: 7)
        .contentShape(Rectangle())
        .onTapGesture { openGate = gate }
    }

    private var emptyGateHint: some View {
        HStack(spacing: 8) {
            Text("لا أوراد هنا — تصفّح المكتبة وأضِف،")
                .font(.subheadline)
                .foregroundStyle(WrdColor.faint)
            Button {
                showSuggested = true
            } label: {
                Text("أو اختر من المقترحة")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(WrdColor.gold)
            }
            .buttonStyle(.plain)
        }
    }

    private func heroRow(_ wird: Wird) -> some View {
        let done = store.isDone(wird)
        return HStack(spacing: 12) {
            Button {
                if done {
                    store.resetToday(wird)
                    Haptics.light()
                } else {
                    store.markDone(wird)
                    Haptics.success()
                }
            } label: {
                Image(systemName: done ? "checkmark.circle" : "circle")
                    .font(.title3)
                    .foregroundStyle(done ? WrdColor.gold : WrdColor.muted)
            }
            .buttonStyle(.plain)
            Text(wird.title)
                .font(.body)
                .foregroundStyle(done ? WrdColor.muted : WrdColor.ink)
                .lineLimit(1)
            Spacer()
            if wird.targetCount > 1 {
                Text("\(arabicNumber(store.count(for: wird)))/\(arabicNumber(wird.targetCount))")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(WrdColor.goldDeep)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .wrdWash(strong: !done, cornerRadius: 13)
        .contentShape(Rectangle())
        .onTapGesture { activeWird = wird }
    }

    // MARK: Compact tiles

    private func compactTile(_ gate: Gate) -> some View {
        let items = store.awrad(in: gate)
        let done = items.filter { store.isDone($0) }.count
        return VStack(spacing: 8) {
            GateRing(progress: store.progress(of: gate), size: 46)
            Text(gate.arabicTitle)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text("\(arabicNumber(done)) من \(arabicNumber(items.count))")
                .font(.footnote)
                .foregroundStyle(WrdColor.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .wrdWash(cornerRadius: 18)
        .contentShape(Rectangle())
        .onTapGesture { openGate = gate }
    }

    // MARK: أوراد الأحوال

    private var generalRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: Gate.general.arabicTitle)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(AdhkarLibrary.occasions.items) { wird in
                        VStack(spacing: 6) {
                            Image(systemName: symbol(for: wird.title))
                                .font(.body)
                                .foregroundStyle(WrdColor.gold)
                                .frame(width: 52, height: 52)
                                .background(Circle().fill(WrdColor.wash))
                            Text(wird.title)
                                .font(.footnote)
                                .foregroundStyle(WrdColor.muted)
                                .lineLimit(1)
                        }
                        .onTapGesture { activeWird = wird }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func symbol(for title: String) -> String {
        if title.contains("طعام") { return "fork.knife" }
        if title.contains("سفر") { return "airplane" }
        if title.contains("منزل") { return "house" }
        if title.contains("خلاء") { return "drop" }
        if title.contains("كرب") { return "heart" }
        return "sparkles"
    }
}

// MARK: - Gate detail sheet

struct GateDetailView: View {
    @Environment(WrdStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let gate: Gate
    @State private var activeWird: Wird?
    @State private var showSuggested = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(store.awrad(in: gate)) { wird in
                        row(wird)
                    }
                    if store.awrad(in: gate).isEmpty {
                        VStack(spacing: 14) {
                            Text("لا أوراد في هذه البوابة")
                                .font(.body)
                                .foregroundStyle(WrdColor.muted)
                            Text("تصفّح المكتبة وأضِف ما تحب — وتختار البوابة عند الإضافة")
                                .font(.footnote)
                                .foregroundStyle(WrdColor.faint)
                            Button {
                                showSuggested = true
                            } label: {
                                Label("الأوراد المقترحة — اختر منها", systemImage: "wand.and.stars")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(WrdColor.gold)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Capsule().fill(WrdColor.goldWash))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 40)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(WrdColor.ground.ignoresSafeArea())
            .navigationTitle(gate.arabicTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("تمّ") { dismiss() }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .sheet(item: $activeWird) { wird in
            CounterView(wird: wird)
        }
        .sheet(isPresented: $showSuggested) {
            SuggestedAwradView()
        }
    }

    private func row(_ wird: Wird) -> some View {
        let done = store.isDone(wird)
        return HStack(spacing: 12) {
            Button {
                if done {
                    store.resetToday(wird)
                    Haptics.light()
                } else {
                    store.markDone(wird)
                    Haptics.success()
                }
            } label: {
                Image(systemName: done ? "checkmark.circle" : "circle")
                    .font(.title3)
                    .foregroundStyle(done ? WrdColor.gold : WrdColor.muted)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 2) {
                Text(wird.title)
                    .font(.body)
                    .foregroundStyle(done ? WrdColor.muted : WrdColor.ink)
                if wird.targetCount > 1 {
                    Text("\(arabicNumber(store.count(for: wird))) من \(arabicNumber(wird.targetCount))")
                        .font(.footnote)
                        .foregroundStyle(WrdColor.faint)
                }
            }
            Spacer()
            if !done {
                Text(wird.targetCount > 1 ? "سبّح" : "اقرأ")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(WrdColor.gold)
            }
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 12)
        .wrdWash(strong: !done, cornerRadius: 13)
        .contentShape(Rectangle())
        .onTapGesture { activeWird = wird }
    }
}

#Preview {
    TodayView()
        .environment(WrdStore())
        .environment(\.layoutDirection, .rightToLeft)
}
