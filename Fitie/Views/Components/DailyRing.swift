import SwiftUI

/// Apple Fitness–style daily completion ring.
struct DailyRing: View {
    let achieved: Int
    let total: Int
    var size: CGFloat = 76
    var lineWidth: CGFloat = 9

    private var fraction: Double {
        total == 0 ? 0 : Double(achieved) / Double(total)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.accent.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.0001, min(1, fraction)))
                .stroke(Theme.accent.gradient,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: fraction)
            VStack(spacing: -2) {
                Text("\(achieved)")
                    .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .animation(.snappy, value: achieved)
                Text("/ \(total)")
                    .font(.system(size: size * 0.18, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel("오늘 습관")
        .accessibilityValue("\(total)개 중 \(achieved)개 달성")
    }
}
