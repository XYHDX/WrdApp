import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// The tasbīḥ counter — tap the big ring area to count. A feather-tap per count,
/// a deeper pulse every 33, and the kindle when the target is reached.
struct CounterView: View {
    @Environment(WrdStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let wird: Wird
    @State private var count: Int = 0
    @State private var kindled = false

    private var target: Int { max(wird.targetCount, 1) }
    private var progress: Double { min(Double(count) / Double(target), 1) }
    private var isLongText: Bool { (wird.text?.count ?? 0) > 180 }

    var body: some View {
        VStack(spacing: 18) {
            header

            VStack(spacing: 6) {
                Text(wird.title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                if let source = wird.source {
                    Text(source)
                        .font(.caption)
                        .foregroundStyle(WrdColor.goldDeep)
                }
            }

            if let text = wird.text {
                ScrollView {
                    Text(text)
                        .font(isLongText ? .body : .title3)
                        .foregroundStyle(WrdColor.inkAlways)
                        .multilineTextAlignment(.center)
                        .lineSpacing(isLongText ? 7 : 10)
                        .padding(18)
                        .frame(maxWidth: .infinity)
                }
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(WrdColor.parchmentAlways))
                .shadow(color: Color.black.opacity(0.1), radius: 14, y: 6)
                .frame(maxHeight: isLongText ? 420 : 240)
            }

            Spacer(minLength: 0)

            // The counting area — one big, obvious target.
            Button {
                advance()
            } label: {
                ZStack {
                    Circle().fill(WrdColor.wash)
                    Circle().stroke(WrdColor.goldWash, lineWidth: 8).padding(10)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(WrdColor.gold, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .padding(10)
                    VStack(spacing: 2) {
                        Text(arabicNumber(count))
                            .font(.system(size: isLongText ? 32 : 44, weight: .semibold))
                            .foregroundStyle(kindled ? WrdColor.gold : WrdColor.ink)
                        Text(kindled ? "أُضيء" : "من \(arabicNumber(target))")
                            .font(.caption)
                            .foregroundStyle(kindled ? WrdColor.gold : WrdColor.muted)
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(width: isLongText ? 150 : 210, height: isLongText ? 150 : 210)
            .shadow(color: kindled ? WrdColor.gold.opacity(0.45) : Color.clear, radius: 24)
            .animation(.spring(duration: 0.5), value: progress)

            Text(kindled ? "تقبّل الله" : "انقر الدائرة للعدّ")
                .font(.footnote)
                .foregroundStyle(kindled ? WrdColor.gold : WrdColor.faint)

            Button {
                dismiss()
            } label: {
                Text(kindled ? "تمّ" : "رجوع")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(kindled ? WrdColor.ground : WrdColor.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(kindled ? WrdColor.gold : WrdColor.wash))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 14)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WrdColor.ground.ignoresSafeArea())
        .presentationDragIndicator(.visible)
        .onAppear {
            count = store.count(for: wird)
            kindled = count >= target
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(WrdColor.muted)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(WrdColor.wash))
            }
            .buttonStyle(.plain)
            Spacer()
            if wird.gate != .general {
                Text(wird.gate.arabicTitle)
                    .font(.caption)
                    .foregroundStyle(WrdColor.faint)
            }
            if count > 0 {
                Button {
                    count = 0
                    kindled = false
                    store.resetToday(wird)
                    Haptics.light()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(WrdColor.muted)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(WrdColor.wash))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func advance() {
        guard count < target else { return }
        count += 1
        store.setCount(count, for: wird)

        if count >= target {
            Haptics.success()
        } else if count % 33 == 0 {
            Haptics.medium()
        } else {
            Haptics.light()
        }

        if count >= target {
            withAnimation(.spring(duration: 0.6)) { kindled = true }
        }
    }
}
