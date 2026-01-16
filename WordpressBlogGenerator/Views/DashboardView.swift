import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var session: UserSession

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Welcome \(session.user?.name ?? "")")
                .font(.largeTitle)

            HStack(spacing: 16) {
                StatCard(title: "API Usage", value: "12,345", detail: "+25% from last month")
                StatCard(title: "Active Models", value: "8", detail: "+2 new models")
                StatCard(title: "Users", value: "1,250", detail: "+10% from last month")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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

#Preview {
    DashboardView()
        .environmentObject(UserSession())
}
