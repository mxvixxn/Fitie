import Testing
@testable import Fitie

struct TemplatePhraserTests {
    @Test func positiveMoodSentence() async {
        let insight = ConditionInsight(habitID: .init(), habitName: "걷기", metric: .mood,
                                       delta: 1.4, sampleAchieved: 4, sampleOther: 3)
        let s = await TemplatePhraser().phrase(insight)
        #expect(s.contains("걷기"))
        #expect(s.contains("기분"))
        #expect(s.contains("1.4"))
        #expect(s.contains("높"))
    }

    @Test func negativeEnergySentence() async {
        let insight = ConditionInsight(habitID: .init(), habitName: "야식", metric: .energy,
                                       delta: -0.8, sampleAchieved: 5, sampleOther: 5)
        let s = await TemplatePhraser().phrase(insight)
        #expect(s.contains("에너지"))
        #expect(s.contains("0.8"))
        #expect(s.contains("낮"))
    }
}
