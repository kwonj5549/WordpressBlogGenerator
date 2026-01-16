import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: UserSession
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sign in")
                .font(.title2)

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            Button(isLoading ? "Signing In..." : "Sign In") {
                Task {
                    errorMessage = nil
                    isLoading = true
                    do {
                        try await session.login(email: email, password: password)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                    isLoading = false
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(UserSession())
}
