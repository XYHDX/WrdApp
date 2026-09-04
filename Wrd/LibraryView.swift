import SwiftUI

struct LibraryView: View {
    @Environment(WrdStore.self) private var store
    @State private var showCompose = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    composeRow
                    VStack(spacing: 8) {
                        ForEach(AdhkarLibrary.all) { category in
                            NavigationLink(value: category.id) {
                                categoryRow(category)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Text("كل ذكرٍ بمصدره — والمحتوى في مراجعةٍ علمية قبل الإطلاق.")
                        .font(.caption2)
                        .foregroundStyle(WrdColor.faint)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(WrdColor.ground.ignoresSafeArea())
            .scrollIndicators(.hidden)
            .navigationTitle("المكتبة")
            .navigationDestination(for: String.self) { categoryID in
                if let category = AdhkarLibrary.all.first(where: { $0.id == categoryID }) {
                    CategoryView(category: category)
                }
            }
        }
        .sheet(isPresented: $showCompose) {
            ComposeWirdView()
        }
    }

    private var composeRow: some View {
        Button {
            showCompose = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.title3.weight(.light))
                    .foregroundStyle(WrdColor.gold)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(WrdColor.goldWash))
                VStack(alignment: .leading, spacing: 1) {
                    Text("أنشئ وِردك الخاص")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(WrdColor.gold)
                    Text("دعاء شخصي، عدد تسبيح، أو نية تحفظها")
                        .font(.caption2)
                        .foregroundStyle(WrdColor.muted)
                }
                Spacer()
            }
            .padding(14)
            .wrdWash(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }

    private func categoryRow(_ category: AdhkarLibrary.Category) -> some View {
        HStack(spacing: 12) {
            Image(systemName: category.symbol)
                .foregroundStyle(WrdColor.gold)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(category.title)
                    .font(.subheadline.weight(.medium))
                Text(category.subtitle)
                    .font(.caption2)
                    .foregroundStyle(WrdColor.muted)
            }
            Spacer()
            Image(systemName: "chevron.backward")
                .font(.caption)
                .foregroundStyle(WrdColor.faint)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .wrdWash(cornerRadius: 16)
    }
}

// MARK: - Category detail

struct CategoryView: View {
    @Environment(WrdStore.self) private var store
    let category: AdhkarLibrary.Category
    @State private var activeWird: Wird?
    @State private var pendingWird: Wird?

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(category.items) { wird in
                    itemCard(wird)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(WrdColor.ground.ignoresSafeArea())
        .scrollIndicators(.hidden)
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeWird) { wird in
            CounterView(wird: wird)
        }
        .confirmationDialog("أين تُضيف هذا الوِرد؟",
                            isPresented: Binding(get: { pendingWird != nil },
                                                 set: { if !$0 { pendingWird = nil } }),
                            titleVisibility: .visible) {
            ForEach([Gate.morning, .afterPrayer, .night, .general]) { gate in
                Button(gate.arabicTitle) {
                    if let wird = pendingWird {
                        store.add(wird, to: gate)
                        Haptics.medium()
                    }
                    pendingWird = nil
                }
            }
            Button("إلغاء", role: .cancel) { pendingWird = nil }
        }
    }

    private func itemCard(_ wird: Wird) -> some View {
        let saved = store.contains(wird)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(wird.title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                if wird.targetCount > 1 {
                    Text("يُكرَّر ×\(arabicNumber(wird.targetCount))")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(WrdColor.gold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(WrdColor.goldWash))
                }
            }
            if let text = wird.text {
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(WrdColor.muted)
                    .lineLimit(3)
                    .lineSpacing(5)
            }
            HStack {
                if let source = wird.source {
                    Text(source)
                        .font(.caption2)
                        .foregroundStyle(WrdColor.goldDeep)
                }
                Spacer()
                Button {
                    if saved { store.remove(wird) } else { pendingWird = wird }
                } label: {
                    Text(saved ? "في أورادي ✓" : "أضِف إلى وِردي")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(saved ? WrdColor.muted : WrdColor.ground)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(saved ? WrdColor.wash : WrdColor.gold))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .wrdWash(cornerRadius: 18)
        .contentShape(Rectangle())
        .onTapGesture { activeWird = wird }
    }
}

// أورادي lives in its own tab now — see MyAwradView.swift.
