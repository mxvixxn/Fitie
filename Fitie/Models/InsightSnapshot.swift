import Foundation
import SwiftData

@Model
final class InsightSnapshot {
    var generatedAt: Date
    var sentences: [String]

    init(generatedAt: Date, sentences: [String]) {
        self.generatedAt = generatedAt
        self.sentences = sentences
    }
}
