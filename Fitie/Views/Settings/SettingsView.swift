import SwiftUI

struct SettingsView: View {
    let health: HealthDataSource
    @State private var requested = false

    var body: some View {
        NavigationStack {
            List {
                Section("건강 데이터") {
                    Button("HealthKit 권한 요청") {
                        Task { @MainActor in
                            try? await health.requestAuthorization()
                            requested = true
                        }
                    }
                    if requested {
                        Text("권한 요청을 보냈어요. 설정 > 개인정보 보호 > 건강에서 확인할 수 있어요.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section("홈 화면 위젯") {
                    Text("위젯은 Apple Developer Program 가입 후 추가할 수 있어요.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("정보") {
                    LabeledContent("버전", value: "0.1.0")
                }
            }
            .navigationTitle("설정")
        }
    }
}
