import ActivityKit
import WidgetKit
import SwiftUI

struct FitieLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FitieActivityAttributes.self) { context in
            HStack(spacing: 12) {
                Image(systemName: "figure.walk").font(.title2)
                VStack(alignment: .leading) {
                    Text(context.attributes.habitName).font(.headline)
                    ProgressView(value: context.state.progress)
                }
                Text("\(context.state.elapsedMinutes)/\(context.attributes.goalMinutes)분")
                    .font(.caption).monospacedDigit()
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Text("\(context.attributes.habitName) \(context.state.elapsedMinutes)분")
                }
            } compactLeading: {
                Image(systemName: "figure.walk")
            } compactTrailing: {
                Text("\(Int(context.state.progress * 100))%")
            } minimal: {
                Image(systemName: "figure.walk")
            }
        }
    }
}
