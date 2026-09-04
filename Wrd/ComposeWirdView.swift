import SwiftUI

/// Compose your own wird — a personal duʿā', a dhikr count, or an intention.
struct ComposeWirdView: View {
    @Environment(WrdStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var text = ""
    @State private var gate: Gate = .morning
    @State private var hasCount = false
    @State private var targetCount = 7
    @State private var hasReminder = false
    @State private var reminderMinutes = 6 * 60

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("الوِرد") {
                    WrdField(placeholder: "عنوان الوِرد — مثال: دعاءٌ لوالدتي", text: $title)
                    WrdField(placeholder: "النص (اختياري)", text: $text, vertical: true)
                }

                Section("التوقيت") {
                    Picker("البوابة", selection: $gate) {
                        ForEach(Gate.allCases) { gate in
                            Text(gate.arabicTitle).tag(gate)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("العدد") {
                    Toggle("وِردٌ بعدد (تسبيح)", isOn: $hasCount)
                    if hasCount {
                        HStack {
                            Text("العدد")
                            Spacer()
                            TextField("٧", value: $targetCount, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 80)
                                .padding(.vertical, 4)
                                .background(RoundedRectangle(cornerRadius: 8).fill(WrdColor.wash))
                            Stepper("", value: $targetCount, in: 1...1000)
                                .labelsHidden()
                        }
                        HStack(spacing: 8) {
                            quickCount(3)
                            quickCount(7)
                            quickCount(10)
                            quickCount(33)
                            quickCount(100)
                        }
                    }
                }

                Section("التذكير") {
                    Toggle("ذكّرني يوميًا في وقتٍ أحدده", isOn: $hasReminder)
                    if hasReminder {
                        DatePicker("الوقت", selection: reminderBinding, displayedComponents: .hourAndMinute)
                    }
                }

                Section {
                    Text("وِردك الخاص يبقى على جهازك — خاصٌّ بك دائمًا.")
                        .font(.caption)
                        .foregroundStyle(WrdColor.muted)
                }
            }
            .scrollContentBackground(.hidden)
            .background(WrdColor.ground.ignoresSafeArea())
            .navigationTitle("وِردٌ جديد")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") { saveWird() }
                        .disabled(!canSave)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }
                }
            }
        }
        .tint(WrdColor.gold)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func quickCount(_ value: Int) -> some View {
        Button {
            targetCount = value
        } label: {
            Text(arabicNumber(value))
                .font(.caption.weight(.medium))
                .foregroundStyle(targetCount == value ? WrdColor.ground : WrdColor.gold)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(Capsule().fill(targetCount == value ? WrdColor.gold : WrdColor.goldWash))
        }
        .buttonStyle(.plain)
    }

    private var reminderBinding: Binding<Date> {
        Binding<Date>(
            get: {
                let start = Calendar.current.startOfDay(for: Date())
                return Calendar.current.date(byAdding: .minute, value: reminderMinutes, to: start) ?? start
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                reminderMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            }
        )
    }

    private func saveWird() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var wird = Wird(
            title: title.trimmingCharacters(in: .whitespaces),
            text: trimmedText.isEmpty ? nil : trimmedText,
            source: nil,
            gate: gate,
            targetCount: hasCount ? max(targetCount, 1) : 1,
            isCustom: true
        )
        wird.reminderMinutes = hasReminder ? reminderMinutes : nil
        store.add(wird)
        NotificationManager.reschedule(store: store)
        dismiss()
    }
}
