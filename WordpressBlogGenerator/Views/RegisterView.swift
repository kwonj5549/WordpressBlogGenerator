import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var session: UserSession
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create account")
                .font(.title2)

            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            Button(isLoading ? "Signing Up..." : "Sign Up") {
                Task {
                    errorMessage = nil
                    isLoading = true
                    do {
                        try await session.register(name: name, email: email, password: password)
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
    RegisterView()
        .environmentObject(UserSession())
}
