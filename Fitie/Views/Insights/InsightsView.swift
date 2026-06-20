import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \InsightSnapshot.generatedAt, order: .reverse) private var snapshots: [InsightSnapshot]
    @Query private var conditions: [ConditionEntry]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("이번 주 인사이트").font(.headline)
                        if let sentences = snapshots.first?.sentences, !sentences.isEmpty {
                            ForEach(sentences, id: \.self) { s in
                                Label(s, systemImage: "sparkles").font(.callout)
                            }
                        } else {
                            Text("데이터가 더 모이면 인사이트를 보여드려요.")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .glassCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("컨디션 추세").font(.headline)
                        if conditions.isEmpty {
                            Text("컨디션을 기록하면 추세가 보여요.")
                                .foregroundStyle(.secondary)
                        } else {
                            Chart(conditions.sorted { $0.day < $1.day }) { c in
                                LineMark(x: .value("날짜", c.day), y: .value("기분", c.mood))
                                    .foregroundStyle(by: .value("지표", "기분"))
                                LineMark(x: .value("날짜", c.day), y: .value("에너지", c.energy))
                                    .foregroundStyle(by: .value("지표", "에너지"))
                            }
                            .chartForegroundStyleScale(["기분": Theme.mood, "에너지": Theme.achieved])
                            .frame(height: 200)
                        }
                    }
                    .glassCard()
                }
                .padding(16)
                .padding(.bottom, 8)
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("인사이트")
        }
    }
}
