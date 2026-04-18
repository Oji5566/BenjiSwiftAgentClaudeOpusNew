import Foundation

/// JSON shape exported when the user taps "Export Data". Stable, versioned,
/// and human-readable. Mirrors the schema the web app emitted, with `notes`
/// stripped per the web `exportData` implementation.
public struct ExportPayload: Codable, Equatable {
    public var username: String
    public var exportedAt: Date
    public var settings: EarningSettingsDTO
    public var categories: [String]
    public var entries: [EntryDTO]

    public init(username: String, exportedAt: Date, settings: EarningSettingsDTO, categories: [String], entries: [EntryDTO]) {
        self.username = username
        self.exportedAt = exportedAt
        self.settings = settings
        self.categories = categories
        self.entries = entries
    }
}

public struct EarningSettingsDTO: Codable, Equatable {
    public var incomeType: IncomeType
    public var incomeAmount: Double
    public var hoursPerWeek: Double
    public var realWageEnabled: Bool
    public var monthlyFixedExpenses: Double
    public var onboardingComplete: Bool

    public init(_ s: EarningSettings, onboardingComplete: Bool) {
        self.incomeType = s.incomeType
        self.incomeAmount = s.incomeAmount
        self.hoursPerWeek = s.hoursPerWeek
        self.realWageEnabled = s.realWageEnabled
        self.monthlyFixedExpenses = s.monthlyFixedExpenses
        self.onboardingComplete = onboardingComplete
    }
}

public struct EntryDTO: Codable, Equatable, Identifiable {
    public var id: String
    public var amount: Double
    public var minutes: Double
    public var decision: Decision
    public var name: String
    public var category: String
    public var timestamp: Date

    public init(id: String, amount: Double, minutes: Double, decision: Decision, name: String, category: String, timestamp: Date) {
        self.id = id
        self.amount = amount
        self.minutes = minutes
        self.decision = decision
        self.name = name
        self.category = category
        self.timestamp = timestamp
    }
}

/// Encodes/decodes export payloads with stable, pretty formatting.
public enum ExportEncoder {
    public static func encode(_ payload: ExportPayload) throws -> Data {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        enc.dateEncodingStrategy = .iso8601
        return try enc.encode(payload)
    }

    public static func decode(_ data: Data) throws -> ExportPayload {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try dec.decode(ExportPayload.self, from: data)
    }

    /// Suggested filename, e.g. `benji-alex-2026-04-18.json`.
    public static func suggestedFilename(username: String, on date: Date = Date()) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        let safeUsername = username.replacingOccurrences(of: "/", with: "_")
        return "benji-\(safeUsername)-\(f.string(from: date)).json"
    }
}
