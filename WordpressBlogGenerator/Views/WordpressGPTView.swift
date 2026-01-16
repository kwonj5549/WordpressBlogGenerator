import SwiftUI
import Combine

struct WordpressGPTView: View {
    @EnvironmentObject var session: UserSession
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel = WordpressGPTViewModel()

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            ScrollView {
                mainContent
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            ScrollView {
                advancedSidebar
            }
            .frame(minWidth: 280, idealWidth: 320, maxWidth: 360, alignment: .top)
        }
        .padding(24)
        .task {
            await viewModel.loadInitialData(session: session)
        }
    }

    private var mainContent: some View {
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
        }
    }

    private var advancedSidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            configSection
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
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
        GroupBox("Site") {
            VStack(alignment: .leading, spacing: 12) {
                if let selected = viewModel.siteOptions.first(where: { $0.url == viewModel.selectedSiteURL }),
                   let imageUrl = selected.imageUrl,
                   let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image.resizable().scaledToFit()
                        default:
                            Image(systemName: "photo")
                        }
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                HStack {
                    Text("Site")
                    Picker("Site", selection: $viewModel.selectedSiteURL) {
                        Text("Custom").tag("")
                        if viewModel.siteOptions.isEmpty {
                            Text(viewModel.isLoadingSites ? "Loading sites..." : "No sites available")
                                .tag("")
                        } else {
                            ForEach(viewModel.siteOptions) { site in
                                Text(site.name).tag(site.url as String)
                            }

                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: viewModel.selectedSiteURL) { newValue in
                        if !newValue.isEmpty {
                            viewModel.siteURL = newValue
                        }
                    }

                    Button {
                        Task {
                            await viewModel.fetchSites(session: session)
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoadingSites)
                }

                TextField("https://example.com", text: $viewModel.siteURL)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: viewModel.siteURL) { newValue in
                        viewModel.updateSelectedSiteURL(from: newValue)
                    }

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
                    Picker("Model", selection: $viewModel.config.model) {
                        if viewModel.modelOptions.isEmpty {
                            Text(viewModel.isLoadingModels ? "Loading models..." : "No models available")
                                .tag(viewModel.config.model)
                        } else {
                            ForEach(viewModel.modelOptions, id: \.value) { option in
                                Text(option.label).tag(option.value)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                }
                if let description = viewModel.selectedModelOption?.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
    @Published var isLoadingModels = false
    @Published var isLoadingSites = false
    @Published var modelOptions: [ModelOption] = []
    @Published var siteOptions: [WordPressSite] = []
    @Published var selectedSiteURL = ""

    var selectedModelOption: ModelOption? {
        modelOptions.first { $0.value == config.model }
    }

    func loadInitialData(session: UserSession) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchAuthStatus(session: session) }
            group.addTask { await self.fetchSiteURL(session: session) }
            group.addTask { await self.fetchSites(session: session) }
            group.addTask { await self.fetchConfig(session: session) }
            group.addTask { await self.fetchModelOptions(session: session) }
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
            updateSelectedSiteURL(from: siteURL)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchSites(session: UserSession) async {
        isLoadingSites = true
        defer { isLoadingSites = false }
        do {
            let response: WordPressSitesResponse = try await session.apiClient.request("wp/sites")
            siteOptions = response.sites
            updateSelectedSiteURL(from: siteURL)
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
            updateSelectedSiteURL(from: siteURL)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchConfig(session: UserSession) async {
        do {
            let response: WordPressConfig = try await session.apiClient.request("wp/config")
            config = response
            if !modelOptions.isEmpty,
               !modelOptions.contains(where: { $0.value == config.model }),
               let firstModel = modelOptions.first {
                config.model = firstModel.value
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchModelOptions(session: UserSession) async {
        isLoadingModels = true
        defer { isLoadingModels = false }
        do {
            let response: ModelsResponse = try await session.apiClient.request("models")
            modelOptions = response.models
            if !modelOptions.contains(where: { $0.value == config.model }),
               let firstModel = modelOptions.first {
                config.model = firstModel.value
            }
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

    func updateSelectedSiteURL(from url: String) {
        if siteOptions.contains(where: { $0.url == url }) {
            selectedSiteURL = url
        } else {
            selectedSiteURL = ""
        }
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

struct WordPressSitesResponse: Codable {
    let sites: [WordPressSite]
}
struct WordPressSite: Codable, Identifiable, Hashable {
    // Use url as a stable id (works great for Pickers / ForEach)
    var id: String { url }

    let name: String
    let url: String
    let imageUrl: String?

    private enum CodingKeys: String, CodingKey {
        case name
        case url
        case imageUrl
    }
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

struct ModelsResponse: Codable {
    let models: [ModelOption]
}

struct ModelOption: Codable {
    let value: String
    let label: String
    let description: String?
    let requiresReasoning: Bool
}

#Preview {
    WordpressGPTView()
        .environmentObject(UserSession())
}
