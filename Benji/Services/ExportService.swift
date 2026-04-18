import Foundation
import UniformTypeIdentifiers

/// Builds export payloads from the SwiftData model and writes them to a
/// temporary file for the system share sheet to consume.
enum ExportService {

    /// Build the in-memory payload for a user.
    static func payload(for user: UserAccount, exportedAt: Date = Date()) -> ExportPayload {
        let entries = user.entries
            .sorted { $0.timestamp > $1.timestamp }
            .map { $0.dto }
        let cats = user.orderedCategories.map { $0.name }
        let settingsDTO = EarningSettingsDTO(user.earningSettings,
                                             onboardingComplete: user.onboardingComplete)
        return ExportPayload(username: user.username,
                             exportedAt: exportedAt,
                             settings: settingsDTO,
                             categories: cats,
                             entries: entries)
    }

    /// Encode `payload` to JSON and write it to a temporary file.
    /// Returns the URL, suitable for use with `ShareLink`.
    @discardableResult
    static func writeTemporaryFile(for payload: ExportPayload) throws -> URL {
        let data = try ExportEncoder.encode(payload)
        let name = ExportEncoder.suggestedFilename(username: payload.username,
                                                   on: payload.exportedAt)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }
}
