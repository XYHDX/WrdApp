import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// WRD color system — parchment by day, candlelight by night.
/// Rules: gold is earned; no borders anywhere; never blue-black, never pure black, never cold blues.
enum WrdColor {

    // MARK: Grounds
    /// Parchment (light) / Candlelight (dark)
    static let ground = dynamicColor(light: 0xF7F1E2, dark: 0x1D1710)
    static let groundHigh = dynamicColor(light: 0xFFFDF6, dark: 0x241C12)

    // MARK: Content
    static let ink = dynamicColor(light: 0x2B2118, dark: 0xF0E6D2)
    static let muted = dynamicColor(light: 0x7A6E55, dark: 0xA79878)
    static let faint = dynamicColor(light: 0xB0A488, dark: 0x5E5850)

    // MARK: Gold — marks completed worship and primary actions only
    static let gold = dynamicColor(light: 0x8E6D1F, dark: 0xD6B25E)
    static let goldDeep = dynamicColor(light: 0x6E5416, dark: 0xB08D36)

    // MARK: Washes — containment is a soft fill + shadow, never an outline
    static let wash = dynamicColor(light: 0x54401F, dark: 0x54401F, lightAlpha: 0.06, darkAlpha: 0.26)
    static let washStrong = dynamicColor(light: 0x54401F, dark: 0x54401F, lightAlpha: 0.10, darkAlpha: 0.40)
    static let goldWash = dynamicColor(light: 0x8E6D1F, dark: 0xD6B25E, lightAlpha: 0.10, darkAlpha: 0.12)

    // MARK: The mushaf is parchment in BOTH themes — ink on paper is the tradition
    static let parchmentAlways = Color(hexValue: 0xF7F1E2)
    static let inkAlways = Color(hexValue: 0x2B2118)
}

// MARK: - Cross-platform dynamic color

private func dynamicColor(light: UInt32, dark: UInt32,
                          lightAlpha: Double = 1, darkAlpha: Double = 1) -> Color {
    #if canImport(UIKit)
    return Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hexValue: dark, alpha: darkAlpha)
            : UIColor(hexValue: light, alpha: lightAlpha)
    })
    #elseif canImport(AppKit)
    return Color(NSColor(name: nil, dynamicProvider: { appearance in
        let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        return isDark ? NSColor(hexValue: dark, alpha: darkAlpha)
                      : NSColor(hexValue: light, alpha: lightAlpha)
    }))
    #else
    return Color(hexValue: light, alpha: lightAlpha)
    #endif
}

extension Color {
    init(hexValue: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hexValue >> 16) & 0xFF) / 255,
                  green: Double((hexValue >> 8) & 0xFF) / 255,
                  blue: Double(hexValue & 0xFF) / 255,
                  opacity: alpha)
    }
}

#if canImport(UIKit)
extension UIColor {
    convenience init(hexValue: UInt32, alpha: Double = 1) {
        self.init(red: CGFloat((hexValue >> 16) & 0xFF) / 255,
                  green: CGFloat((hexValue >> 8) & 0xFF) / 255,
                  blue: CGFloat(hexValue & 0xFF) / 255,
                  alpha: CGFloat(alpha))
    }
}
#elseif canImport(AppKit)
extension NSColor {
    convenience init(hexValue: UInt32, alpha: Double = 1) {
        self.init(srgbRed: CGFloat((hexValue >> 16) & 0xFF) / 255,
                  green: CGFloat((hexValue >> 8) & 0xFF) / 255,
                  blue: CGFloat(hexValue & 0xFF) / 255,
                  alpha: CGFloat(alpha))
    }
}
#endif
