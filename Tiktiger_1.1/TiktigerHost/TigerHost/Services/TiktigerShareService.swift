import Foundation
import UIKit

@MainActor
final class TiktigerShareService {
    static let shared = TiktigerShareService()

    enum ShareError: LocalizedError {
        case missingFile
        case unreadableFile

        var errorDescription: String? {
            switch self {
            case .missingFile: return "Share file is missing"
            case .unreadableFile: return "Share file is not readable"
            }
        }
    }

    private let diagnostics = TiktigerDeviceDiagnostics.shared

    private init() {}

    func validate(fileURL: URL) throws -> URL {
        diagnostics.recordFeatureEvent(feature: "Share", event: "action_started", detail: "share requested")
        diagnostics.recordFeatureEvent(feature: "Share", event: "service_called", detail: "TiktigerShareService.validate")
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            diagnostics.recordFeatureEvent(feature: "Share", event: "result_failed", detail: "missing file")
            diagnostics.recordFeatureEvent(feature: "Share", event: "failure", detail: "missing file")
            throw ShareError.missingFile
        }
        guard FileManager.default.isReadableFile(atPath: fileURL.path) else {
            diagnostics.recordFeatureEvent(feature: "Share", event: "result_failed", detail: "unreadable file")
            diagnostics.recordFeatureEvent(feature: "Share", event: "failure", detail: "unreadable file")
            throw ShareError.unreadableFile
        }
        diagnostics.recordFeatureEvent(feature: "Share", event: "state_changed", detail: "validated file=\(fileURL.lastPathComponent)")
        return fileURL
    }

    func recordCompletion(activityType: UIActivity.ActivityType?, completed: Bool, error: Error?, fileURLs: [URL]) {
        if let error {
            diagnostics.recordFeatureEvent(feature: "Share", event: "result_failed", detail: error.localizedDescription)
            diagnostics.recordFeatureEvent(feature: "Share", event: "failure", detail: error.localizedDescription)
        } else if completed {
            diagnostics.recordFeatureEvent(feature: "Share", event: "result_success", detail: "activity=\(activityType?.rawValue ?? "unknown")")
            diagnostics.recordFeatureEvent(feature: "Share", event: "success", detail: "activity=\(activityType?.rawValue ?? "unknown")")
        } else {
            diagnostics.recordFeatureEvent(feature: "Share", event: "cancel", detail: "user cancelled share sheet")
        }

        for fileURL in fileURLs where fileURL.path.hasPrefix(FileManager.default.temporaryDirectory.path) {
            try? FileManager.default.removeItem(at: fileURL)
        }
        if fileURLs.contains(where: { $0.path.hasPrefix(FileManager.default.temporaryDirectory.path) }) {
            diagnostics.recordFeatureEvent(feature: "Share", event: "state_changed", detail: "temporary file cleanup attempted after completion")
        }
    }
}
