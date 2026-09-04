import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Haptics — real light in the hand. Silent on the simulator (it has no engine,
/// and every attempt would spam the console).
enum Haptics {
    static func light() {
        #if canImport(UIKit) && !targetEnvironment(simulator)
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.6)
        #endif
    }
    static func medium() {
        #if canImport(UIKit) && !targetEnvironment(simulator)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
    static func success() {
        #if canImport(UIKit) && !targetEnvironment(simulator)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}

/// Soft wash surface — WRD never draws borders; containment is a fill + shadow.
struct WashBackground: ViewModifier {
    var strong = false
    var cornerRadius: CGFloat = 22

    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(strong ? WrdColor.washStrong : WrdColor.wash)
        )
    }
}

extension View {
    func wrdWash(strong: Bool = false, cornerRadius: CGFloat = 22) -> some View {
        modifier(WashBackground(strong: strong, cornerRadius: cornerRadius))
    }
}

/// The gate progress ring — light being kindled.
struct GateRing: View {
    var progress: Double
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            Circle()
                .stroke(WrdColor.goldWash, lineWidth: size * 0.08)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(WrdColor.gold, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .fill(WrdColor.gold)
                .frame(width: size * 0.14, height: size * 0.14)
        }
        .frame(width: size, height: size)
        .animation(.spring(duration: 0.8), value: progress)
    }
}

/// Arabic-first text field. The system placeholder follows the DEVICE language
/// (left-aligned on English iPhones), so WRD draws its own — it always sits
/// on the right, where Arabic belongs, whatever the phone's language.
struct WrdField: View {
    let placeholder: String
    @Binding var text: String
    var vertical: Bool = false

    var body: some View {
        ZStack(alignment: vertical ? .topLeading : .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(WrdColor.faint)
                    .allowsHitTesting(false)
            }
            if vertical {
                TextField("", text: $text, axis: .vertical)
                    .lineLimit(3...8)
                    .multilineTextAlignment(.leading)
            } else {
                TextField("", text: $text)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote.weight(.medium))
            .foregroundStyle(WrdColor.goldDeep)
    }
}
