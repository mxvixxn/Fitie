import ActivityKit
import Foundation

@MainActor
@Observable
final class SessionController {
    private(set) var isRunning = false

    // ActivityKit's `Activity` is a non-Sendable class, so it must never cross an actor
    // boundary. We hold it outside observation/isolation and only touch it from the
    // `nonisolated async` helpers below, which call update/end without any actor hop.
    @ObservationIgnored nonisolated(unsafe) private var activity: Activity<FitieActivityAttributes>?
    @ObservationIgnored private var startedAt: Date?
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var goalMinutes = 10

    func start(habitName: String, goalMinutes: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, activity == nil else { return }
        self.goalMinutes = goalMinutes
        startedAt = Date()
        let attributes = FitieActivityAttributes(habitName: habitName, goalMinutes: goalMinutes)
        let initial = FitieActivityAttributes.ContentState(progress: 0, elapsedMinutes: 0)
        activity = try? Activity.request(attributes: attributes,
                                         content: .init(state: initial, staleDate: nil))
        isRunning = activity != nil
        guard isRunning else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func tick() {
        guard let startedAt else { return }
        let minutes = Int(Date().timeIntervalSince(startedAt) / 60)
        let progress = min(1.0, Double(minutes) / Double(goalMinutes))
        Task { await self.pushUpdate(progress: progress, minutes: minutes) }
    }

    func stop() {
        timer?.invalidate(); timer = nil
        let goal = goalMinutes
        isRunning = false
        startedAt = nil
        Task { await self.endActivity(goalMinutes: goal) }
    }

    nonisolated private func pushUpdate(progress: Double, minutes: Int) async {
        guard let activity else { return }
        let state = FitieActivityAttributes.ContentState(progress: progress, elapsedMinutes: minutes)
        await activity.update(.init(state: state, staleDate: nil))
    }

    nonisolated private func endActivity(goalMinutes: Int) async {
        guard let activity else { return }
        let state = FitieActivityAttributes.ContentState(progress: 1, elapsedMinutes: goalMinutes)
        await activity.end(.init(state: state, staleDate: nil), dismissalPolicy: .immediate)
        self.activity = nil
    }
}
