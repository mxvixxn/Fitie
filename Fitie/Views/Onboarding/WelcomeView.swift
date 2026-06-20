import SwiftUI

struct WelcomeView: View {
    var requestHealth: () async -> Void
    var onFinish: () -> Void

    @State private var connecting = false
    @State private var connected = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer(minLength: 24)

                BrandMark(size: 104)
                Text("Fitie")
                    .font(.largeTitle).fontWeight(.bold)
                    .padding(.top, 18)
                Text("습관은 알아서 채워지고,\n컨디션까지 보여드려요.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                VStack(spacing: 20) {
                    feature("checkmark.seal.fill", "자동으로 확인돼요",
                            "걷기·운동·수면을 Apple 건강이 채워줘요.")
                    feature("sparkles", "컨디션 인사이트",
                            "어떤 습관이 내 기분을 좋게 하는지 짚어줘요.")
                    feature("lock.fill", "온전히 기기 안에서",
                            "데이터는 기기에만, 온디바이스 AI로 분석해요.")
                }
                .padding(.top, 40)
                .padding(.horizontal, 12)

                Spacer()

                VStack(spacing: 10) {
                    Button {
                        connecting = true
                        Task {
                            await requestHealth()
                            connecting = false
                            connected = true
                        }
                    } label: {
                        Label(connected ? "건강 데이터 연결됨" : "건강 데이터 연결",
                              systemImage: connected ? "checkmark" : "heart.text.square")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .disabled(connecting || connected)

                    Button("시작하기", action: onFinish)
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .fontDesign(.rounded)
            .tint(Theme.accent)
        }
    }

    private func feature(_ symbol: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title2).foregroundStyle(Theme.accent)
                .frame(width: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
