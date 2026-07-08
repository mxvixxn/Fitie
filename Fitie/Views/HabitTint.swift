import SwiftUI

extension Habit {
    /// The habit's display color — custom if set, otherwise the metric's system color.
    var tintColor: Color {
        colorHex.isEmpty ? Theme.metricColor(rule.metric) : Theme.paletteColor(colorHex)
    }
}
