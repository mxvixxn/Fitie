import SwiftUI

struct SettingsView: View {
    let health: HealthDataSource
    @State private var requested = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("건강 데이터").font(.headline)
                        Button("HealthKit 권한 요청") {
                            Task { @MainActor in
                                try? await health.requestAuthorization()
                                requested = true
                            }
                        }
                        .buttonStyle(.glass)
                        if requested {
                            Text("권한 요청을 보냈어요. 설정 > 개인정보 보호 > 건강에서 확인할 수 있어요.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("홈 화면 위젯").font(.headline)
                        Text("위젯은 Apple Developer Program 가입 후 추가할 수 있어요.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("정보").font(.headline)
                        HStack {
                            Text("버전")
                            Spacer()
                            Text("0.1.0").foregroundStyle(.secondary)
                        }
                        .font(.callout)
                    }
                    .glassCard()
                }
                .padding(16)
                .padding(.bottom, 8)
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("설정")
        }
    }
}
