import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var session: UserSession
    @State private var summary: DashboardSummary?
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Welcome \(summary?.welcomeName ?? session.user?.name ?? "")")
                .font(.largeTitle)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 16) {
                StatCard(title: "API Usage", value: summary?.stats.apiUsage.formatted() ?? "--", detail: "Requests processed")
                StatCard(title: "Active Models", value: summary?.stats.activeModels.formatted() ?? "--", detail: "Models available")
                StatCard(title: "Users", value: summary?.stats.users.formatted() ?? "--", detail: "Registered users")
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
            let response: DashboardSummary = try await session.apiClient.request("dashboard/summary")
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

struct DashboardSummary: Codable {
    let welcomeName: String
    let stats: DashboardStats
}

struct DashboardStats: Codable {
    let apiUsage: Int
    let activeModels: Int
    let users: Int
}

#Preview {
    DashboardView()
        .environmentObject(UserSession())
}
