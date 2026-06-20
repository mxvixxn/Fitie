import SwiftUI
import SwiftData

struct RootView: View {
    @State private var refresher: RefreshController
    private let health: HealthDataSource

    init(container: ModelContainer) {
        let health = HealthKitDataSource()
        self.health = health
        _refresher = State(initialValue: RefreshController(
            container: container,
            health: health,
            phraser: FoundationModelsPhraser.makeAvailable()))
    }

    var body: some View {
        TabView {
            TodayView(refresher: refresher)
                .tabItem { Label("오늘", systemImage: "checklist") }
            InsightsView()
                .tabItem { Label("인사이트", systemImage: "sparkles") }
            SettingsView(health: health)
                .tabItem { Label("설정", systemImage: "gearshape") }
        }
    }
}
