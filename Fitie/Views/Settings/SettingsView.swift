import SwiftUI

struct SettingsView: View {
    let health: HealthDataSource
    @State private var requested = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        Task { @MainActor in
                            try? await health.requestAuthorization()
                            requested = true
                        }
                    } label: {
                        Label("HealthKit 권한 요청", systemImage: "heart.text.square")
                    }
                } header: {
                    Text("건강 데이터")
                } footer: {
                    Text(requested
                         ? "권한 요청을 보냈어요. 설정 > 개인정보 보호 > 건강에서 확인할 수 있어요."
                         : "걷기·운동·수면 데이터로 습관을 자동 확인합니다. 데이터는 기기에만 저장돼요.")
                }

                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("홈 화면 위젯")
                            Text("Apple Developer Program 가입 후 추가할 수 있어요.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "square.grid.2x2")
                    }
                } header: {
                    Text("곧 추가될 기능")
                }

                Section("정보") {
                    LabeledContent {
                        Text("0.1.0").foregroundStyle(.secondary)
                    } label: {
                        Label("버전", systemImage: "info.circle")
                    }
                    LabeledContent {
                        Text("온디바이스 AI").foregroundStyle(.secondary)
                    } label: {
                        Label("인사이트 엔진", systemImage: "sparkles")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .tint(Theme.accent)
            .navigationTitle("설정")
        }
    }
}
