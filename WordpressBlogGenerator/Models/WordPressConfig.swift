import Foundation

struct WordPressConfig: Codable {
    var model: String
    var useCustomPrompt: Bool
    var customPrompt: String
    var autosend: Bool
    var frequencyPenalty: Double
    var presencePenalty: Double
    var temperature: Double
    var maxTokens: Int
    var reasoningEffort: String

    static let `default` = WordPressConfig(
        model: "gpt-4.5-preview",
        useCustomPrompt: false,
        customPrompt: "Write a very long and detailied blog post about {topic} with a concise and appealing title, a summary of the whole blog post right below, and the full content in the style of an expert with 15 years of experience without explicitly mentioning this.",
        autosend: false,
        frequencyPenalty: 0,
        presencePenalty: 0.35,
        temperature: 0.7,
        maxTokens: 4000,
        reasoningEffort: "medium"
    )
}
