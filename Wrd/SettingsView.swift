import SwiftUI

/// Settings — theme, city & prayer times, and the reminders.
struct SettingsView: View {
    @Environment(WrdStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var permissionDenied = false
    @State private var showSuggested = false

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            Form {
                Section("أنت") {
                    WrdField(placeholder: "اسمك الكريم", text: $store.userName)
                    Toggle("خطٌّ كبير — راحةً للعين", isOn: $store.largeText)
                }
                .listRowBackground(WrdColor.groundHigh)

                Section("المظهر") {
                    Picker("السمة", selection: $store.theme) {
                        ForEach(WrdTheme.allCases) { theme in
                            Text(theme.arabicTitle).tag(theme)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                .listRowBackground(WrdColor.groundHigh)

                Section("المدينة ومواقيت الصلاة") {
                    Picker("المدينة", selection: $store.city) {
                        ForEach(City.all) { city in
                            Text(city.arabicName).tag(city)
                        }
                    }
                    .pickerStyle(.menu)
                    prayerTimesRow
                    Text("تُحسب المواقيت على جهازك بلا إنترنت (رابطة العالم الإسلامي). تحديد الموقع تلقائيًا قادم قريبًا.")
                        .font(.caption)
                        .foregroundStyle(WrdColor.muted)
                }
                .listRowBackground(WrdColor.groundHigh)

                Section("التذكير") {
                    Toggle("ذكّرني بأورادي", isOn: $store.remindersEnabled)
                        .onChange(of: store.remindersEnabled) { _, enabled in
                            if enabled {
                                Task {
                                    let granted = await NotificationManager.requestPermission()
                                    if granted {
                                        NotificationManager.reschedule(store: store)
                                    } else {
                                        store.remindersEnabled = false
                                        permissionDenied = true
                                    }
                                }
                            } else {
                                NotificationManager.reschedule(store: store)
                            }
                        }
                    if store.remindersEnabled {
                        Toggle("نداء عند كل صلاة", isOn: $store.adhanEnabled)
                        Text("تنبيه عند دخول وقت كل صلاة، وتذكيرٌ بوِرد الصباح بعد الفجر وبالوِرد الليلي بعد العشاء — كلها بمواقيت \(store.city.arabicName).")
                            .font(.caption)
                            .foregroundStyle(WrdColor.muted)
                    }
                }
                .listRowBackground(WrdColor.groundHigh)

                Section("الأوراد") {
                    Button {
                        showSuggested = true
                    } label: {
                        Label("الأوراد المقترحة — اختر منها", systemImage: "wand.and.stars")
                            .foregroundStyle(WrdColor.gold)
                    }
                    Text("مجموعة مختارة للبداية — تختار منها ما يناسبك، ولا شيء يُفرض.")
                        .font(.caption)
                        .foregroundStyle(WrdColor.muted)
                }
                .listRowBackground(WrdColor.groundHigh)

                Section("عن وِرْد") {
                    HStack {
                        Text("وِردُكَ نُورُك")
                            .foregroundStyle(WrdColor.gold)
                        Spacer()
                        Text("النسخة ٠٫٤")
                            .font(.caption)
                            .foregroundStyle(WrdColor.faint)
                    }
                    Text("لا إعلانات، ولا بيع بيانات — عبادتُك لك وحدك.")
                        .font(.caption)
                        .foregroundStyle(WrdColor.muted)
                }
                .listRowBackground(WrdColor.groundHigh)
            }
            .scrollContentBackground(.hidden)
            .background(WrdColor.ground.ignoresSafeArea())
            .navigationTitle("الإعدادات")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("تمّ") { dismiss() }
                }
            }
            .sheet(isPresented: $showSuggested) {
                SuggestedAwradView()
            }
            .alert("التنبيهات غير مسموحة", isPresented: $permissionDenied) {
                Button("حسنًا", role: .cancel) {}
            } message: {
                Text("اسمح بالتنبيهات لتطبيق وِرْد من إعدادات النظام حتى نذكّرك بأورادك.")
            }
        }
        .tint(WrdColor.gold)
        .environment(\.layoutDirection, .rightToLeft)
        .onDisappear {
            NotificationManager.reschedule(store: store)
        }
    }

    private var prayerTimesRow: some View {
        let prayers = store.todayPrayers
        let order: [PrayerName] = [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha]
        return VStack(spacing: 8) {
            ForEach(order) { prayer in
                if let time = prayers.time(prayer) {
                    HStack {
                        Text(prayer.arabicName)
                            .font(.subheadline)
                            .foregroundStyle(prayer == .sunrise ? WrdColor.faint : WrdColor.ink)
                        Spacer()
                        Text(prayerTimeString(time))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(prayer == .sunrise ? WrdColor.faint : WrdColor.goldDeep)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
