import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct FoundationModelsPhraser: InsightPhraser {
    private let fallback = TemplatePhraser()

    func phrase(_ insight: ConditionInsight) async -> String {
        let base = await fallback.phrase(insight)
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, *) else { return base }
        let model = SystemLanguageModel.default
        guard case .available = model.availability else { return base }
        do {
            let session = LanguageModelSession(
                instructions: """
                너는 건강 습관 앱의 카피라이터야. 주어진 한국어 문장을 더 따뜻하고 친근하게
                한 문장으로 다듬어줘. 절대 숫자나 사실을 바꾸지 말고, 의학적 조언은 하지 마.
                """
            )
            let response = try await session.respond(to: "다듬을 문장: \(base)")
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            let magnitude = String(format: "%.1f", abs(insight.delta))
            return text.contains(magnitude) ? text : base
        } catch {
            return base
        }
        #else
        return base
        #endif
    }

    static func makeAvailable() -> InsightPhraser {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), case .available = SystemLanguageModel.default.availability {
            return FoundationModelsPhraser()
        }
        #endif
        return TemplatePhraser()
    }
}
