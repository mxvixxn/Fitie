import SwiftUI
import SwiftData

struct SettingsView: View {
    let health: HealthDataSource
    @Environment(\.modelContext) private var context
    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue
    @State private var requested = false
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("화면") {
                    Picker("외형", selection: $appearanceRaw) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.label).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

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
                        Text("온디바이스").foregroundStyle(.secondary)
                    } label: {
                        Label("인사이트 엔진", systemImage: "sparkles")
                    }
                    Label("모든 데이터는 기기에만 저장돼요.", systemImage: "lock.shield")
                        .font(.subheadline)
                }

                Section {
                    Button(role: .destructive) { showResetConfirm = true } label: {
                        Label("모든 데이터 초기화", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("설정")
            .confirmationDialog("모든 습관·기록·인사이트가 삭제됩니다.",
                                isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("전부 삭제", role: .destructive, action: resetAll)
                Button("취소", role: .cancel) {}
            }
        }
    }

    private func resetAll() {
        try? context.delete(model: Habit.self)
        try? context.delete(model: DailyResult.self)
        try? context.delete(model: ConditionEntry.self)
        try? context.delete(model: InsightSnapshot.self)
        try? context.save()
    }
}
