import SwiftUI

/// A one-shot confetti burst, used when the day's habits are all complete.
struct ConfettiView: View {
    private struct Piece: Identifiable {
        let id = UUID()
        let x = CGFloat.random(in: -160...160)
        let fall = CGFloat.random(in: 320...640)
        let size = CGFloat.random(in: 6...11)
        let spin = Double.random(in: 180...900)
        let delay = Double.random(in: 0...0.25)
        let color: Color = [.indigo, .purple, .green, .orange, .blue, .pink].randomElement()!
    }

    private let pieces = (0..<46).map { _ in Piece() }
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(pieces) { p in
                RoundedRectangle(cornerRadius: 2)
                    .fill(p.color)
                    .frame(width: p.size, height: p.size * 1.6)
                    .rotationEffect(.degrees(animate ? p.spin : 0))
                    .offset(x: p.x, y: animate ? p.fall : -30)
                    .opacity(animate ? 0 : 1)
                    .animation(.easeOut(duration: 1.7).delay(p.delay), value: animate)
            }
        }
        .onAppear { animate = true }
        .allowsHitTesting(false)
    }
}
