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

/// Fitie design language — Apple-native, modeled on Health / Fitness.
/// Colors are the adaptive system palette so dark mode is handled by the OS.
enum Theme {
    static let accent = Color.indigo       // CTA / selection (matches AccentColor asset)
    static let mood = Color.purple         // condition (mood) — Health mental wellbeing
    static let achieved = Color.green      // completed — Fitness exercise ring
    static let streak = Color.orange       // flame — Fitness move
    static let inProgress = Color.orange   // partial progress

    /// Habit color choices — stored as the light-mode hex of a system color.
    static let palette = ["FF9500", "FFCC00", "34C759", "30B0C7",
                          "007AFF", "5856D6", "AF52DE", "FF2D55"]

    /// Resolves a stored palette hex to its adaptive system color so dark mode
    /// gets the correct variant. Unknown (legacy) hexes render as-is.
    static func paletteColor(_ hex: String) -> Color {
        let raw = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        switch raw.uppercased() {
        case "FF9500": return .orange
        case "FFCC00": return .yellow
        case "34C759": return .green
        case "30B0C7": return .teal
        case "007AFF": return .blue
        case "5856D6": return .indigo
        case "AF52DE": return .purple
        case "FF2D55": return .pink
        default: return Color(hex: hex)
        }
    }

    /// Default metric colors, matching the Health app's category colors.
    static func metricColor(_ metric: HealthMetric) -> Color {
        switch metric {
        case .steps: return .orange          // activity
        case .water: return .cyan            // hydration
        case .exerciseMinutes: return .green // exercise ring
        case .mindfulMinutes: return .teal   // mindfulness
        case .sleepStart: return .indigo     // sleep
        }
    }
}

extension View {
    /// Standard inset-grouped content card, as in Health / Fitness.
    func card(cornerRadius: CGFloat = 20) -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground),
                        in: .rect(cornerRadius: cornerRadius, style: .continuous))
    }

    /// System grouped background, full bleed.
    func screenBackground() -> some View {
        background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
