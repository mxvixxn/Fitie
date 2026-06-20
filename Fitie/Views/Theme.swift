import SwiftUI

extension Color {
    init(hex: String) {
        let raw = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var rgb: UInt64 = 0
        Scanner(string: raw).scanHexInt64(&rgb)
        self.init(.sRGB,
                  red: Double((rgb >> 16) & 0xFF) / 255,
                  green: Double((rgb >> 8) & 0xFF) / 255,
                  blue: Double(rgb & 0xFF) / 255,
                  opacity: 1)
    }

    init(light: String, dark: String) {
        self.init(UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "시스템"
        case .light: return "라이트"
        case .dark: return "다크"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum Theme {
    // Accents (read well on both light and dark glass)
    static let accent = Color(hex: "5B6BB5")       // indigo-lavender (CTA / selection)
    static let mood = Color(hex: "8E8AD6")         // lavender (condition dots)
    static let achieved = Color(hex: "55B98C")     // mint green
    static let streak = Color(hex: "E08A6E")       // soft coral
    static let inProgress = Color(hex: "CC8A45")   // soft amber

    /// Pastel choices offered when customizing a habit's color.
    static let palette = ["4FB58E", "4E92C9", "D08A5E", "8E84C9",
                          "4FB0A6", "E08A6E", "5B6BB5", "C06AA6"]

    static func metricColor(_ metric: HealthMetric) -> Color {
        switch metric {
        case .steps: return Color(hex: "4FB58E")          // mint
        case .water: return Color(hex: "4E92C9")          // sky
        case .exerciseMinutes: return Color(hex: "D08A5E") // peach
        case .mindfulMinutes: return Color(hex: "4FB0A6")  // teal
        case .sleepStart: return Color(hex: "8E84C9")      // lavender
        }
    }

    // Soft pastel gradient backdrop (light + warm dark variants)
    static var background: LinearGradient {
        LinearGradient(
            colors: [
                Color(light: "E7EEF8", dark: "191C24"),
                Color(light: "ECF1EC", dark: "161B19"),
                Color(light: "F6EEE9", dark: "201A18"),
                Color(light: "F0EAF6", dark: "1B1722")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing)
    }
}

extension View {
    /// Wraps content in a rounded Liquid Glass card.
    func glassCard(cornerRadius: CGFloat = 26, tint: Color? = nil) -> some View {
        let glass: Glass = tint.map { Glass.regular.tint($0) } ?? .regular
        return self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(glass, in: .rect(cornerRadius: cornerRadius))
    }

    /// Adds the app's pastel gradient as a full-bleed background.
    func screenBackground() -> some View {
        background(Theme.background.ignoresSafeArea())
    }
}
