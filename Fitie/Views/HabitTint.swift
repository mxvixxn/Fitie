import SwiftUI

extension Habit {
    /// The habit's display color — custom if set, otherwise the metric's pastel.
    var tintColor: Color {
        colorHex.isEmpty ? Theme.metricColor(rule.metric) : Color(hex: colorHex)
    }
}
