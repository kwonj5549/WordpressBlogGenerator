import SwiftUI

struct WordpressGPTView: View {
    @EnvironmentObject var session: UserSession
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel = WordpressGPTViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if let statusMessage = viewModel.statusMessage {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                authSection
                siteURLSection
                promptSection
                responseSection
                configSection
            }
            .padding(24)
        }
        .task {
            await viewModel.loadInitialData(session: session)
        }
    }

    private var header: some View {
        HStack {
            Text("WordPress GPT")
                .font(.largeTitle)
            Spacer()
            if viewModel.wpAuthStatus {
                Label("Authenticated", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            } else {
                Label("Not connected", systemImage: "xmark.seal")
                    .foregroundStyle(.orange)
            }
        }
    }

    private var authSection: some View {
        GroupBox("WordPress Authentication") {
            HStack(spacing: 12) {
                Button("Authenticate") {
                    Task {
                        await viewModel.startAuth(session: session, openURL: openURL)
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Check Status") {
                    Task {
                        await viewModel.fetchAuthStatus(session: session)
                    }
                }

                Button("Revoke") {
                    Task {
                        await viewModel.revokeAuth(session: session)
                    }
                }
                .disabled(!viewModel.wpAuthStatus)
            }
        }
    }

    private var siteURLSection: some View {
        GroupBox("Site URL") {
            HStack {
                TextField("https://example.com", text: $viewModel.siteURL)
                    .textFieldStyle(.roundedBorder)
                Button("Save") {
                    Task {
                        await viewModel.saveSiteURL(session: session)
                    }
                }
            }
        }
    }

    private var promptSection: some View {
        GroupBox("Prompt") {
            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $viewModel.prompt)
                    .frame(minHeight: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2))
                    )
                Button(viewModel.isGenerating ? "Generating..." : "Generate") {
                    Task {
                        await viewModel.generate(session: session)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isGenerating)
            }
        }
    }

    private var responseSection: some View {
        GroupBox("Response") {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.responseTitle.isEmpty ? "Title will appear here" : viewModel.responseTitle)
                    .font(.headline)
                TextEditor(text: $viewModel.responseContent)
                    .frame(minHeight: 220)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2))
                    )
            }
        }
    }

    private var configSection: some View {
        GroupBox("Advanced Config") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Model")
                    TextField("Model", text: $viewModel.config.model)
                        .textFieldStyle(.roundedBorder)
                }

                Toggle("Use Custom Prompt", isOn: $viewModel.config.useCustomPrompt)
                TextEditor(text: $viewModel.config.customPrompt)
                    .frame(minHeight: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2))
                    )
                    .disabled(!viewModel.config.useCustomPrompt)

                Toggle("Autosend", isOn: $viewModel.config.autosend)

                sliderRow(title: "Temperature", value: $viewModel.config.temperature, range: 0...1)
                sliderRow(title: "Frequency Penalty", value: $viewModel.config.frequencyPenalty, range: 0...2)
                sliderRow(title: "Presence Penalty", value: $viewModel.config.presencePenalty, range: 0...2)

                Stepper("Max Tokens: \(viewModel.config.maxTokens)", value: $viewModel.config.maxTokens, in: 256...8000, step: 256)

                Picker("Reasoning Effort", selection: $viewModel.config.reasoningEffort) {
                    Text("Low").tag("low")
                    Text("Medium").tag("medium")
                    Text("High").tag("high")
                }
                .pickerStyle(.segmented)

                Button(viewModel.isSavingConfig ? "Saving..." : "Save Config") {
                    Task {
                        await viewModel.saveConfig(session: session)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isSavingConfig)
            }
        }
    }

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(title)
            Slider(value: value, in: range)
            Text(String(format: "%.2f", value.wrappedValue))
                .frame(width: 50, alignment: .trailing)
        }
    }
}

@MainActor
final class WordpressGPTViewModel: ObservableObject {
    @Published var wpAuthStatus = false
    @Published var siteURL = ""
    @Published var prompt = ""
    @Published var responseTitle = ""
    @Published var responseContent = ""
    @Published var config = WordPressConfig.default
    @Published var statusMessage: String?
    @Published var errorMessage: String?
    @Published var isGenerating = false
    @Published var isSavingConfig = false

    func loadInitialData(session: UserSession) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchAuthStatus(session: session) }
            group.addTask { await self.fetchSiteURL(session: session) }
            group.addTask { await self.fetchConfig(session: session) }
        }
    }

    func startAuth(session: UserSession, openURL: OpenURLAction) async {
        errorMessage = nil
        do {
            let response: WordPressAuthStartResponse = try await session.apiClient.request("wp/auth/start")
            if let url = URL(string: response.authUrl) {
                openURL(url)
                statusMessage = "Complete authentication in your browser, then check status."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchAuthStatus(session: UserSession) async {
        errorMessage = nil
        do {
            let response: WordPressAuthStatusResponse = try await session.apiClient.request("wp/auth/status")
            wpAuthStatus = response.wpAuthStatus
            statusMessage = wpAuthStatus ? "WordPress authentication active." : "WordPress authentication required."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func revokeAuth(session: UserSession) async {
        errorMessage = nil
        do {
            _ = try await session.apiClient.request("wp/auth/revoke", method: "POST") as APIClient.EmptyResponse
            wpAuthStatus = false
            statusMessage = "WordPress access revoked."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchSiteURL(session: UserSession) async {
        do {
            let response: WordPressSiteURLResponse = try await session.apiClient.request("wp/site-url")
            siteURL = response.siteUrl ?? ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveSiteURL(session: UserSession) async {
        errorMessage = nil
        let request = WordPressSiteURLRequest(siteUrl: siteURL)
        do {
            let data = try JSONEncoder().encode(request)
            _ = try await session.apiClient.request("wp/site-url", method: "POST", body: data) as APIClient.EmptyResponse
            statusMessage = "Site URL saved."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchConfig(session: UserSession) async {
        do {
            let response: WordPressConfig = try await session.apiClient.request("wp/config")
            config = response
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveConfig(session: UserSession) async {
        errorMessage = nil
        isSavingConfig = true
        do {
            let data = try JSONEncoder().encode(config)
            _ = try await session.apiClient.request("wp/config", method: "POST", body: data) as APIClient.EmptyResponse
            statusMessage = "Config saved."
        } catch {
            errorMessage = error.localizedDescription
        }
        isSavingConfig = false
    }

    func generate(session: UserSession) async {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a prompt."
            return
        }

        errorMessage = nil
        isGenerating = true

        let request = WordPressGenerateRequest(
            prompt: prompt,
            siteUrl: siteURL.isEmpty ? nil : siteURL,
            model: config.model,
            config: config
        )

        do {
            let data = try JSONEncoder().encode(request)
            let response: WordPressGenerateResponse = try await session.apiClient.request("wp/generate", method: "POST", body: data)
            if let generation = response.generations.first {
                responseTitle = generation.title
                responseContent = generation.htmlContent
                statusMessage = "Generation completed."
            } else {
                errorMessage = "No content returned."
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }
}

struct WordPressAuthStartResponse: Codable {
    let authUrl: String
    let state: String
}

struct WordPressAuthStatusResponse: Codable {
    let wpAuthStatus: Bool
}

struct WordPressSiteURLRequest: Codable {
    let siteUrl: String
}

struct WordPressSiteURLResponse: Codable {
    let siteUrl: String?
}

struct WordPressGenerateRequest: Codable {
    let prompt: String
    let siteUrl: String?
    let model: String
    let config: WordPressConfig
}

struct WordPressGenerateResponse: Codable {
    let generations: [WordPressGeneration]
}

struct WordPressGeneration: Codable {
    let title: String
    let htmlContent: String
}

#Preview {
    WordpressGPTView()
        .environmentObject(UserSession())
}
