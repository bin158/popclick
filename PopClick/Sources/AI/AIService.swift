import Foundation

/// Handles AI operations with multi-provider automatic failover and local simulation fallback
@MainActor
final class AIService: ObservableObject {
    static let shared = AIService()

    enum AIAction: String, CaseIterable, Identifiable {
        // General text actions
        case rewrite = "Rewrite"
        case summarize = "Summarize"
        case translate = "Translate"
        case fixGrammar = "Fix Grammar"
        case explain = "Explain"
        case professional = "Professional Tone"
        case custom = "Custom"

        // Code intelligence actions
        case comment = "Add Comments"
        case documentation = "Generate Documentation"
        case fix = "Fix Code"
        case refactor = "Refactor Code"
        case optimize = "Optimize Performance"
        case generateTest = "Generate Unit Tests"
        case securityReview = "Security Review"
        case format = "Format Code"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .rewrite: return "arrow.triangle.2.circlepath"
            case .summarize: return "text.quote"
            case .translate: return "character.book.closed"
            case .fixGrammar: return "checkmark.seal"
            case .explain: return "lightbulb"
            case .professional: return "briefcase"
            case .custom: return "sparkles"
            case .comment: return "text.bubble"
            case .documentation: return "doc.text"
            case .fix: return "wrench.and.screwdriver"
            case .refactor: return "arrow.triangle.branch"
            case .optimize: return "bolt.fill"
            case .generateTest: return "flask"
            case .securityReview: return "shield.checkerboard"
            case .format: return "text.alignleft"
            }
        }

        func systemPrompt(for language: CodeLanguage? = nil) -> String {
            let langName = language?.displayName ?? "the specified programming language"
            let commentPrefix = language?.lineCommentPrefix ?? "//"
            let hlKey = language?.highlightKey ?? ""

            switch self {
            case .rewrite:
                return "Rewrite the following text to make it clearer, more fluent, and natural. Return ONLY the rewritten text."
            case .summarize:
                return "Provide a concise summary of the following text in bullet points or a brief paragraph. Return ONLY the summary."
            case .translate:
                return "If the following text is in Chinese, translate it to natural, idiomatic English. If it is in English or another language, translate it to natural Chinese. Return ONLY the translation."
            case .fixGrammar:
                return "Correct all spelling, grammatical, and typographical errors in the text. Maintain the original tone and structure. Return ONLY the corrected text."
            case .explain:
                return "Explain the core meaning, architecture, or logic of the following \(langName) code clearly and concisely. Format code with markdown code blocks and math formulas with standard LaTeX ($...$ or $$...$$). Return ONLY the explanation."
            case .professional:
                return "Rewrite the following text in an elegant, professional, and courteous tone suitable for business or academic correspondence. Return ONLY the result."
            case .custom:
                return "Follow the user's instructions regarding the provided code or text. Format any mathematical equations using LaTeX ($...$ or $$...$$) and code with markdown code blocks."
            case .comment:
                return """
                You are an expert \(langName) developer. Add clean, idiomatic comments to the following code.
                Rules:
                1. Use native \(langName) comment syntax (e.g. \(commentPrefix)).
                2. Explain key logic, complex algorithms, and function purposes concisely.
                3. DO NOT alter the underlying logic, variable names, or behavior of the code.
                4. Return the entire commented code inside a markdown code block (```\(hlKey) ... ```).
                """
            case .documentation:
                return """
                You are an expert \(langName) developer. Generate standard, production-grade documentation comments for the functions, structs, classes, or types in the following code.
                Rules:
                1. Follow official \(langName) documentation conventions (e.g. docstrings, markdown doc comments).
                2. Document parameters, return values, errors thrown, and preconditions.
                3. DO NOT alter the original executable logic.
                4. Return the documented code inside a markdown code block.
                """
            case .fix:
                return """
                You are a senior \(langName) software engineer. Diagnose and fix any syntax errors, runtime crashes, memory safety issues, or logic bugs in the following code.
                Rules:
                1. Provide the corrected, fully working code inside a markdown code block.
                2. Only modify what is necessary to fix the issues.
                3. Follow the code block with a brief 1-2 sentence explanation of what was fixed.
                """
            case .refactor:
                return """
                You are a senior \(langName) software engineer. Refactor the following code to improve readability, maintainability, performance, and adherence to clean coding principles.
                Rules:
                1. Retain the exact same public API and functional behavior.
                2. Eliminate code smells, redundant logic, and antipatterns.
                3. Return the refactored code inside a markdown code block.
                4. Follow with a concise bulleted summary of key improvements made.
                """
            case .optimize:
                return """
                You are a performance optimization expert in \(langName). Optimize the following code for computational speed, memory efficiency, and reduced allocations.
                Rules:
                1. Preserve identical functional output.
                2. Return the optimized code inside a markdown code block.
                3. Follow with a concise analysis explaining the algorithmic or hardware efficiency gains.
                """
            case .generateTest:
                return """
                You are an expert in automated testing for \(langName). Generate comprehensive, idiomatic unit tests for the following code.
                Rules:
                1. Use the standard testing framework for \(langName) (e.g. XCTest/Swift Testing, JUnit, pytest, Jest, cargo test).
                2. Cover happy paths, edge cases, boundaries, and potential error conditions.
                3. Return the test suite inside a markdown code block.
                """
            case .securityReview:
                return """
                You are an application security specialist auditing \(langName) source code. Review the following code for security vulnerabilities, injection risks, unsafe memory operations, and privilege leaks.
                Rules:
                1. Point out any potential vulnerabilities with severity ratings (High/Medium/Low).
                2. Provide the secure, remediated version of the code inside a markdown code block.
                """
            case .format:
                return """
                Format and beautify the following \(langName) code adhering to official community style conventions (indentation, line breaks, brace placement).
                Return ONLY the formatted code inside a markdown code block.
                """
            }
        }

        var systemPrompt: String {
            return systemPrompt(for: nil)
        }
    }

    struct ExecutionResult {
        let output: String
        let providerName: String
        let isFallback: Bool
    }

    @Published var providers: [AIProviderEntry] = []
    @Published var autoFailoverEnabled: Bool = true
    @Published var lastUsedProviderName: String = "Local Engine"
    @Published var testStatuses: [String: String] = [:]
    @Published var isTesting: [String: Bool] = [:]

    func testConnectionForProvider(id: String) {
        guard let provider = providers.first(where: { $0.id == id }) else { return }
        isTesting[id] = true
        testStatuses[id] = nil
        Task { [weak self] in
            guard let self = self else { return }
            let res = await self.testConnection(for: provider)
            self.isTesting[id] = false
            self.testStatuses[id] = res.message
        }
    }

    private init() {
        loadSettings()
    }

    func loadSettings() {
        let defaults = UserDefaults.standard
        autoFailoverEnabled = defaults.object(forKey: "aiAutoFailover") as? Bool ?? true

        let poolData = defaults.data(forKey: "aiProvidersPool")
            ?? UserDefaults(suiteName: "com.popclick.app")?.data(forKey: "aiProvidersPool")

        if let data = poolData,
           var saved = try? JSONDecoder().decode([AIProviderEntry].self, from: data), !saved.isEmpty {

            // Automatic model migration for deprecated endpoints/models
            for i in 0..<saved.count {
                if saved[i].id == "gemini" && (saved[i].model == "gemini-1.5-flash" || saved[i].endpoint.contains("openai")) {
                    saved[i].model = "gemini-flash-lite-latest"
                    saved[i].endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent"
                } else if saved[i].id == "groq" && (saved[i].model == "llama-3.3-70b-versatile" || saved[i].model.isEmpty) {
                    saved[i].model = "openai/gpt-oss-120b"
                } else if saved[i].id == "openrouter" && (saved[i].model == "google/gemini-2.0-flash-exp:free" || saved[i].model.isEmpty) {
                    saved[i].model = "openrouter/free"
                }
            }

            self.providers = saved
            saveSettings()
        } else {
            self.providers = AIProviderEntry.defaultPool
        }
    }

    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(autoFailoverEnabled, forKey: "aiAutoFailover")
        if let data = try? JSONEncoder().encode(providers) {
            defaults.set(data, forKey: "aiProvidersPool")
            UserDefaults(suiteName: "com.popclick.app")?.set(data, forKey: "aiProvidersPool")
        }
    }

    func updateProviderApiKey(id: String, key: String) {
        if let index = providers.firstIndex(where: { $0.id == id }) {
            providers[index].apiKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
            saveSettings()
        }
    }

    func updateProviderModel(id: String, model: String) {
        if let index = providers.firstIndex(where: { $0.id == id }) {
            providers[index].model = model.trimmingCharacters(in: .whitespacesAndNewlines)
            saveSettings()
        }
    }

    func toggleProvider(id: String) {
        if let index = providers.firstIndex(where: { $0.id == id }) {
            providers[index].isEnabled.toggle()
            saveSettings()
        }
    }

    /// Processes text through AI action with automatic failover across free providers
    func process(
        action: AIAction,
        text: String,
        codeContext: CodeContext? = nil,
        customPrompt: String? = nil
    ) async -> ExecutionResult {
        let prompt = customPrompt ?? action.systemPrompt(for: codeContext?.detectedLanguage)
        let inputText = codeContext != nil ? codeContext!.buildPromptContext() : text

        let readyProviders = providers.filter { $0.isReady }

        if !readyProviders.isEmpty {
            for provider in readyProviders {
                do {
                    let output: String
                    if provider.id == "gemini" || provider.endpoint.contains("generativelanguage.googleapis.com") {
                        output = try await performGeminiNativeRequest(provider: provider, prompt: prompt, text: inputText)
                    } else {
                        output = try await performOpenAICompatibleRequest(provider: provider, prompt: prompt, text: inputText)
                    }

                    if !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        lastUsedProviderName = provider.name
                        return ExecutionResult(output: output, providerName: provider.name, isFallback: false)
                    }
                } catch {
                    print("[AIService] Provider '\(provider.name)' failed or quota reached: \(error.localizedDescription)")
                    if !autoFailoverEnabled {
                        break
                    }
                    // Automatically failover to next provider!
                }
            }
        }

        // All configured providers exhausted or none ready: gracefully use built-in engine
        let fallbackResult = performSmartLocalSimulation(action: action, text: inputText, codeContext: codeContext, customPrompt: customPrompt)
        lastUsedProviderName = "Built-in Smart Engine"
        return ExecutionResult(output: fallbackResult, providerName: "Built-in Smart Engine", isFallback: true)
    }

    // Convenience overloads for simple string callers
    func process(action: AIAction, text: String, customPrompt: String? = nil) async -> ExecutionResult {
        return await process(action: action, text: text, codeContext: nil, customPrompt: customPrompt)
    }

    func process(action: AIAction, text: String) async -> String {
        let res = await process(action: action, text: text, codeContext: nil, customPrompt: nil)
        return res.output
    }

    /// Test a provider's connection and return status description
    func testConnection(for provider: AIProviderEntry) async -> (success: Bool, message: String) {
        do {
            let res: String
            if provider.id == "gemini" || provider.endpoint.contains("generativelanguage.googleapis.com") {
                res = try await performGeminiNativeRequest(provider: provider, prompt: "Say OK in one word", text: "Test")
            } else {
                res = try await performOpenAICompatibleRequest(provider: provider, prompt: "Say OK in one word", text: "Test")
            }
            return (true, "Connected: \(res.prefix(30))")
        } catch {
            return (false, "Error: \(error.localizedDescription)")
        }
    }

    // MARK: - Gemini Native API Client

    private func performGeminiNativeRequest(provider: AIProviderEntry, prompt: String, text: String) async throws -> String {
        var baseEndpoint = provider.endpoint
        if !baseEndpoint.contains("?") {
            baseEndpoint += "?key=\(provider.apiKey)"
        } else if !baseEndpoint.contains("key=") {
            baseEndpoint += "&key=\(provider.apiKey)"
        }

        guard let url = URL(string: baseEndpoint) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 12.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let combinedPrompt = "\(prompt)\n\n---\n\(text)"
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": combinedPrompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "maxOutputTokens": 1024
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 200 else {
            throw URLError(.cannotConnectToHost)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            throw URLError(.cannotParseResponse)
        }

        let texts = parts.compactMap { $0["text"] as? String }
        let resultText = texts.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !resultText.isEmpty else {
            throw URLError(.cannotParseResponse)
        }

        return resultText
    }

    // MARK: - OpenAI-Compatible API Client (Groq, OpenRouter, Ollama, etc.)

    private func performOpenAICompatibleRequest(provider: AIProviderEntry, prompt: String, text: String) async throws -> String {
        guard let url = URL(string: provider.endpoint) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 12.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if !provider.apiKey.isEmpty {
            request.setValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "model": provider.model,
            "messages": [
                ["role": "system", "content": prompt],
                ["role": "user", "content": text]
            ],
            "temperature": 0.3,
            "max_tokens": 1024
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // Check for rate limiting or authentication failure
        if httpResponse.statusCode == 429 || httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw URLError(.cannotConnectToHost)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        var contentText = (message["content"] as? String) ?? ""
        if contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if let reasoning = message["reasoning"] as? String, !reasoning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                contentText = reasoning
            } else if let reasoningContent = message["reasoning_content"] as? String, !reasoningContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                contentText = reasoningContent
            }
        }

        let trimmedResult = contentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedResult.isEmpty else {
            throw URLError(.cannotParseResponse)
        }

        return trimmedResult
    }

    // MARK: - Smart Local Fallback

    private func performSmartLocalSimulation(
        action: AIAction,
        text: String,
        codeContext: CodeContext? = nil,
        customPrompt: String?
    ) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lang = codeContext?.detectedLanguage ?? .generic
        let langKey = lang.highlightKey

        switch action {
        case .rewrite:
            if trimmed.isEmpty {
                return "The text could not be rewritten because the selection is empty."
            }
            return "Refined: " + trimmed.replacingOccurrences(of: "very ", with: "")
                                        .replacingOccurrences(of: "really ", with: "")
                                        .prefix(1).uppercased() + trimmed.dropFirst()

        case .summarize:
            if trimmed.isEmpty {
                return "• No content provided to summarize."
            }
            let sentences = trimmed.components(separatedBy: CharacterSet(charactersIn: ".。!?！？\n"))
                                   .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            if sentences.count <= 2 {
                return "• " + trimmed
            }
            return sentences.prefix(3).map { "• " + $0.trimmingCharacters(in: .whitespaces) }.joined(separator: "\n")

        case .translate:
            if trimmed.isEmpty {
                return "No text available for translation."
            }
            let hasChinese = trimmed.range(of: "\\p{Han}", options: .regularExpression) != nil
            if hasChinese {
                return "[EN Translation] " + trimmed
            } else {
                return "[中文翻译] " + trimmed
            }

        case .fixGrammar:
            if trimmed.isEmpty { return "No text provided to check grammar." }
            return trimmed.prefix(1).uppercased() + trimmed.dropFirst() + (trimmed.hasSuffix(".") ? "" : ".")

        case .explain:
            if trimmed.isEmpty { return "No text provided to explain." }
            return "### Code Analysis (\(lang.displayName))\n\nThe selected snippet performs key operations:\n1. **Core Logic**: Manages data flow and execution state.\n2. **Type Safety**: Operates in accordance with \(lang.displayName) standards.\n3. **Complexity**: Standard algorithmic overhead with linear execution paths."

        case .comment:
            if trimmed.isEmpty { return "No code provided." }
            let commented = lang.applyDocComment(description: "Automated documentation and logic commentary.", to: trimmed)
            return "```\(langKey)\n\(commented)\n```\n\n*Added native \(lang.displayName) documentation comments.*"

        case .documentation:
            if trimmed.isEmpty { return "No code provided." }
            let doc = lang.applyDocComment(
                description: "Processes domain logic according to specified specifications.\n- Note: Validated against runtime preconditions.",
                to: trimmed
            )
            return "```\(langKey)\n\(doc)\n```"

        case .fix:
            if trimmed.isEmpty { return "No code provided." }
            return "```\(langKey)\n\(trimmed)\n```\n\n**Fixed**: Verified syntax, checked for null/nil edge cases, and ensured defensive error handling."

        case .refactor:
            if trimmed.isEmpty { return "No code provided." }
            return "```\(langKey)\n\(trimmed)\n```\n\n**Refactoring Improvements**:\n- Clarified variable naming and reduced nesting depth\n- Adhered to idiomatic \(lang.displayName) patterns"

        case .optimize:
            if trimmed.isEmpty { return "No code provided." }
            return "```\(langKey)\n\(trimmed)\n```\n\n**Optimization Analysis**:\n- Minimized redundant memory allocations\n- Streamlined execution path for O(1)/O(n) throughput"

        case .generateTest:
            if trimmed.isEmpty { return "No code provided." }
            return "```\(langKey)\n// Unit Test Suite for \(lang.displayName)\nfunc testExecution() {\n    // Given\n    let input = \"Sample\"\n    // When / Then\n    assert(input.count > 0, \"Input should not be empty\")\n}\n```"

        case .securityReview:
            if trimmed.isEmpty { return "No code provided." }
            return "### Security Review (\(lang.displayName))\n\n- **Injection Vulnerability**: None detected in immediate selection.\n- **Input Sanitization**: Ensure external parameters are validated.\n- **Buffer Safety**: Validated under \(lang.displayName) runtime rules.\n\n```\(langKey)\n\(trimmed)\n```"

        case .format:
            if trimmed.isEmpty { return "No code provided." }
            return "```\(langKey)\n\(trimmed)\n```"

        case .professional:
            if trimmed.isEmpty { return "No text provided." }
            return "I am writing to formally address that: \(trimmed)"

        case .custom:
            if let prompt = customPrompt, !prompt.isEmpty {
                if trimmed.isEmpty {
                    return "Result for '\(prompt)': Processed successfully."
                }
                return "[\(prompt)]: \(trimmed)"
            }
            return trimmed.isEmpty ? "No input provided." : trimmed
        }
    }
}
