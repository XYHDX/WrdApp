import SwiftUI

/// The suggested set — you choose which of them enters your space.
struct SuggestedAwradView: View {
    @Environment(WrdStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<UUID> = []

    private var suggestions: [Wird] {
        AdhkarLibrary.starterAwrad.filter { !store.contains($0) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    if suggestions.isEmpty {
                        Text("كل الأوراد المقترحة عندك بالفعل — ما شاء الله")
                            .font(.subheadline)
                            .foregroundStyle(WrdColor.muted)
                            .padding(.top, 40)
                    } else {
                        Text("اختر ما يناسبك — ولا شيء يُفرض عليك")
                            .font(.footnote)
                            .foregroundStyle(WrdColor.faint)
                            .padding(.bottom, 4)
                        ForEach(suggestions) { wird in
                            row(wird)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(WrdColor.ground.ignoresSafeArea())
            .navigationTitle("الأوراد المقترحة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("أضِف \(selected.isEmpty ? "" : arabicNumber(selected.count))") {
                        for wird in suggestions where selected.contains(wird.id) {
                            store.add(wird)
                        }
                        Haptics.medium()
                        dismiss()
                    }
                    .disabled(selected.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("إغلاق") { dismiss() }
                }
            }
        }
        .tint(WrdColor.gold)
        .environment(\.layoutDirection, .rightToLeft)
        .presentationDragIndicator(.visible)
    }

    private func row(_ wird: Wird) -> some View {
        let isSelected = selected.contains(wird.id)
        return HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? WrdColor.gold : WrdColor.muted)
            VStack(alignment: .leading, spacing: 2) {
                Text(wird.title)
                    .font(.body)
                HStack(spacing: 8) {
                    Text(wird.gate.arabicTitle)
                        .font(.caption)
                        .foregroundStyle(WrdColor.goldDeep)
                    if let source = wird.source {
                        Text(source)
                            .font(.caption)
                            .foregroundStyle(WrdColor.muted)
                    }
                }
            }
            Spacer()
            if wird.targetCount > 1 {
                Text("×\(arabicNumber(wird.targetCount))")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(WrdColor.gold)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .wrdWash(strong: isSelected, cornerRadius: 15)
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelected { selected.remove(wird.id) } else { selected.insert(wird.id) }
            Haptics.light()
        }
    }
}
