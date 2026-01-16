import SwiftUI

struct WordpressGPTView: View {
    @State private var wpAuthStatus = false
    @State private var siteURL = ""
    @State private var prompt = ""
    @State private var responseTitle = ""
    @State private var responseContent = ""
    @State private var config = WordPressConfig.default

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("WordPress GPT")
                        .font(.largeTitle)
                    Spacer()
                    if wpAuthStatus {
                        Label("Authenticated", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Button("Unauthenticate") {
                            // TODO: call /wp/auth/revoke
                        }
                    } else {
                        Button("Authenticate") {
                            // TODO: call /wp/auth/start and open ASWebAuthenticationSession
                        }
                    }
                }

                GroupBox("Site URL") {
                    HStack {
                        TextField("https://example.com", text: $siteURL)
                            .textFieldStyle(.roundedBorder)
                        Button("Save") {
                            // TODO: call /wp/site-url
                        }
                    }
                }

                GroupBox("Prompt") {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Write about...", text: $prompt)
                            .textFieldStyle(.roundedBorder)
                        Button("Generate") {
                            // TODO: call /wp/generate
                        }
                    }
                }

                GroupBox("Response") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(responseTitle.isEmpty ? "Title will appear here" : responseTitle)
                            .font(.headline)
                        Text(responseContent.isEmpty ? "Generated content will appear here" : responseContent)
                            .font(.body)
                    }
                }

                GroupBox("Advanced Config") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Use Custom Prompt", isOn: $config.useCustomPrompt)
                        TextField("Custom prompt", text: $config.customPrompt)
                            .textFieldStyle(.roundedBorder)
                        HStack {
                            Text("Temperature")
                            Slider(value: $config.temperature, in: 0...1)
                            Text(String(format: "%.2f", config.temperature))
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}

#Preview {
    WordpressGPTView()
}
