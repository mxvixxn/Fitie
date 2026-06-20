import SwiftUI

/// The Fitie logo motif — a gradient completion ring with a check.
struct BrandMark: View {
    var size: CGFloat = 96

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [Theme.accent, Theme.mood, Theme.achieved, Theme.streak, Theme.accent],
                        center: .center),
                    style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round))
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(Theme.accent)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
