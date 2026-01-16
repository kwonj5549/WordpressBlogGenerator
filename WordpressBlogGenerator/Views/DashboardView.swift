import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var session: UserSession
    @State private var summary: StatsSummary?
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Welcome \(session.user?.name ?? "")")
                    .font(.largeTitle)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                if isLoading {
                    ProgressView()
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 16)], spacing: 16) {
                    StatCard(title: "Generated Today", value: summary?.postsGenerated.today.formatted() ?? "--", detail: "Posts created")
                    StatCard(title: "This Week", value: summary?.postsGenerated.thisWeek.formatted() ?? "--", detail: "Posts created")
                    StatCard(title: "All Time", value: summary?.postsGenerated.allTime.formatted() ?? "--", detail: "Total posts")
                    StatCard(title: "Avg. Gen Time", value: summary?.averageGenerationTimeMs.formatted() ?? "--", detail: "Milliseconds")
                    StatCard(title: "Most Used Model", value: summary?.mostUsedModel ?? "--", detail: "By usage")
                }

                PostsGeneratedChart(summary: summary)
                ModelDistributionChart(summary: summary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            await loadSummary()
        }
    }

    private func loadSummary() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            let response: StatsSummary = try await session.request("stats/summary")
            summary = response
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(value)
                .font(.title)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 180, height: 120, alignment: .topLeading)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2))
        )
    }
}

struct PostsGeneratedChart: View {
    let summary: StatsSummary?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Posts Generated")
                .font(.headline)

            Chart {
                ForEach(postsGeneratedPoints) { point in
                    BarMark(
                        x: .value("Period", point.label),
                        y: .value("Count", point.value)
                    )
                    .foregroundStyle(Color.accentColor)
                }
            }
            .frame(height: 220)
            .chartYScale(domain: 0...(maxPostsGenerated))
        }
        .padding(16)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2))
        )
    }

    private var postsGeneratedPoints: [ChartPoint] {
        let postsGenerated = summary?.postsGenerated
        return [
            ChartPoint(label: "Today", value: postsGenerated?.today ?? 0),
            ChartPoint(label: "This Week", value: postsGenerated?.thisWeek ?? 0),
            ChartPoint(label: "All Time", value: postsGenerated?.allTime ?? 0)
        ]
    }

    private var maxPostsGenerated: Int {
        let maxValue = postsGeneratedPoints.map { $0.value }.max() ?? 0
        return max(1, maxValue)
    }
}

struct ModelDistributionChart: View {
    let summary: StatsSummary?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Model Distribution")
                .font(.headline)

            Chart {
                ForEach(summary?.modelDistribution ?? []) { entry in
                    BarMark(
                        x: .value("Count", entry.count),
                        y: .value("Model", entry.model)
                    )
                    .foregroundStyle(Color.blue.opacity(0.7))
                }
            }
            .frame(height: 220)
        }
        .padding(16)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2))
        )
    }
}

struct ChartPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Int
}

struct StatsSummary: Codable {
    let postsGenerated: PostsGenerated
    let averageGenerationTimeMs: Int
    let mostUsedModel: String?
    let modelDistribution: [ModelUsage]
}

struct PostsGenerated: Codable {
    let today: Int
    let thisWeek: Int
    let allTime: Int
}

struct ModelUsage: Codable, Identifiable {
    let model: String
    let count: Int

    var id: String { model }
}

#Preview {
    DashboardView()
        .environmentObject(UserSession())
}
