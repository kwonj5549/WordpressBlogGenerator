import SwiftUI

struct AuthView: View {
    @State private var selection: AuthSelection = .login

    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome to GPT Toolkit")
                .font(.largeTitle)

            Picker("Authentication", selection: $selection) {
                Text("Login").tag(AuthSelection.login)
                Text("Register").tag(AuthSelection.register)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 320)

            Group {
                switch selection {
                case .login:
                    LoginView()
                case .register:
                    RegisterView()
                }
            }
            .frame(maxWidth: 420)
        }
        .padding(32)
    }
}

enum AuthSelection {
    case login
    case register
}

#Preview {
    AuthView()
        .environmentObject(UserSession())
}
