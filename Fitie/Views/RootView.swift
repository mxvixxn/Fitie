import SwiftUI
import SwiftData

struct RootView: View {
    @State private var refresher: RefreshController
    @State private var tab: Int
    @State private var showWelcome = false
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue
    private let health: HealthDataSource

    init(container: ModelContainer) {
        let health = HealthKitDataSource()
        self.health = health
        _refresher = State(initialValue: RefreshController(
            container: container,
            health: health,
            phraser: FoundationModelsPhraser.makeAvailable()))
        _tab = State(initialValue: Int(ProcessInfo.processInfo.environment["FITIE_TAB"] ?? "") ?? 0)
    }

    private var colorScheme: ColorScheme? {
        (AppearanceMode(rawValue: appearanceRaw) ?? .system).colorScheme
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
        .environment(\.locale, Locale(identifier: "ko_KR"))
        .preferredColorScheme(colorScheme)
        .task { await refresher.run() }
        .onAppear { showWelcome = !hasOnboarded && !SampleData.isSeedMode }
        .fullScreenCover(isPresented: $showWelcome) {
            WelcomeView(
                requestHealth: { try? await health.requestAuthorization() },
                onFinish: { hasOnboarded = true; showWelcome = false })
        }
    }
}
