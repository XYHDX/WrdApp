import SwiftUI

/// أورادي — the private area. The user's own awrād, kept on this device only.
struct MyAwradView: View {
    @Environment(WrdStore.self) private var store
    @State private var showCompose = false
    @State private var showSuggested = false
    @State private var wirdToDelete: Wird?

    var body: some View {
        NavigationStack {
            Group {
                if store.awrad.isEmpty {
                    emptyState
                } else {
                    awradList
                }
            }
            .background(WrdColor.ground.ignoresSafeArea())
            .navigationTitle("أورادي")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCompose = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(WrdColor.gold)
                    }
                }
            }
        }
        .sheet(isPresented: $showCompose) {
            ComposeWirdView()
        }
        .sheet(isPresented: $showSuggested) {
            SuggestedAwradView()
        }
        .alert("حذف الوِرد؟", isPresented: Binding(get: { wirdToDelete != nil },
                                                   set: { if !$0 { wirdToDelete = nil } })) {
            Button("احذف", role: .destructive) {
                if let wird = wirdToDelete {
                    store.remove(wird)
                    NotificationManager.reschedule(store: store)
                    Haptics.light()
                }
                wirdToDelete = nil
            }
            Button("إبقاء", role: .cancel) { wirdToDelete = nil }
        } message: {
            Text("يُحذف «\(wirdToDelete?.title ?? "")» من أورادك — والنور الذي كسبتَه به يبقى لك.")
        }
    }

    private var awradList: some View {
        List {
            Section {
                HStack(spacing: 10) {
                    Image(systemName: "lock")
                        .font(.caption)
                        .foregroundStyle(WrdColor.gold)
                    Text("هذه المساحة خاصة بك — أورادك تبقى على جهازك، ولا يطّلع عليها أحد.")
                        .font(.caption)
                        .foregroundStyle(WrdColor.muted)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            ForEach(Gate.allCases) { gate in
                let items = store.awrad(in: gate)
                if !items.isEmpty {
                    Section {
                        ForEach(items) { wird in
                            row(wird)
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(WrdColor.wash)
                                        .padding(.vertical, 3)
                                )
                                .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            if let index = offsets.first {
                                wirdToDelete = items[index]
                            }
                        }
                    } header: {
                        Text(gate.arabicTitle)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(WrdColor.goldDeep)
                    }
                }
            }
            Section {
                Button {
                    showSuggested = true
                } label: {
                    Label("الأوراد المقترحة — اختر منها", systemImage: "wand.and.stars")
                        .font(.subheadline)
                        .foregroundStyle(WrdColor.gold)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                Text("احذف بلمسة سلة المهملات — والنور الذي كسبتَه يبقى لك.")
                    .font(.caption)
                    .foregroundStyle(WrdColor.faint)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(WrdColor.ground)
    }

    private func row(_ wird: Wird) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(wird.title).font(.subheadline)
                    if wird.isCustom {
                        Text("خاص")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(WrdColor.gold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(WrdColor.goldWash))
                    }
                }
                HStack(spacing: 8) {
                    if let source = wird.source {
                        Text(source).font(.caption2).foregroundStyle(WrdColor.muted)
                    }
                    if let minutes = wird.reminderMinutes {
                        Label(minutesTimeString(minutes), systemImage: "bell")
                            .font(.caption2)
                            .foregroundStyle(WrdColor.goldDeep)
                    }
                }
            }
            Spacer()
            if wird.targetCount > 1 {
                Text("×\(arabicNumber(wird.targetCount))")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(WrdColor.gold)
            }
            Button {
                wirdToDelete = wird
            } label: {
                Image(systemName: "trash")
                    .font(.footnote)
                    .foregroundStyle(WrdColor.faint)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(WrdColor.wash))
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("۞")
                .font(.system(size: 40))
                .foregroundStyle(WrdColor.gold)
            Text("مساحتك تبدأ فارغة — كما ينبغي")
                .font(.title3.weight(.semibold))
            Text("تصفّح المكتبة وأضِف ما يناسبك،\nأو أنشئ وِردك الخاص من الزر أعلاه")
                .font(.subheadline)
                .foregroundStyle(WrdColor.muted)
                .multilineTextAlignment(.center)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MyAwradView()
        .environment(WrdStore())
        .environment(\.layoutDirection, .rightToLeft)
}
