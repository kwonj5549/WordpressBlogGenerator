import SwiftUI

struct MainShellView: View {
    enum Route: Hashable {
        case dashboard
        case wordpress
    }

    @State private var selection: Route = .dashboard
    @EnvironmentObject var session: UserSession

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("Dashboard", systemImage: "square.grid.2x2")
                    .tag(Route.dashboard)
                Label("WordPress GPT", systemImage: "doc.text")
                    .tag(Route.wordpress)
            }
            .listStyle(.sidebar)
            .navigationTitle("GPT Toolkit")
        } detail: {
            switch selection {
            case .dashboard:
                DashboardView()
            case .wordpress:
                WordpressGPTView()
            }
        }
        .toolbar {
            Button("Logout") {
                session.logout()
            }
        }
    }
}

#Preview {
    MainShellView()
        .environmentObject(UserSession())
}
