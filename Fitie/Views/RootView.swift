import SwiftUI
import SwiftData

struct RootView: View {
    @State private var refresher: RefreshController
    @State private var tab = 0
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
        TabView(selection: $tab) {
            TodayView(refresher: refresher, onShowInsights: { tab = 1 })
                .tabItem { Label("오늘", systemImage: "checklist") }
                .tag(0)
            InsightsView()
                .tabItem { Label("인사이트", systemImage: "sparkles") }
                .tag(1)
            SettingsView(health: health)
                .tabItem { Label("설정", systemImage: "gearshape") }
                .tag(2)
        }
        .tint(Theme.accent)
        .fontDesign(.rounded)
    }
}
