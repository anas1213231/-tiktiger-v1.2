import Combine
import Foundation
import SwiftUI

@MainActor
final class TiktigerLocalizationService: ObservableObject {
    static let shared = TiktigerLocalizationService()

    @Published private(set) var language: String

    private let defaults: UserDefaults
    private let diagnostics: TiktigerDeviceDiagnostics

    var layoutDirection: LayoutDirection {
        language == "ar" ? .rightToLeft : .leftToRight
    }

    private init(
        defaults: UserDefaults = .standard,
        diagnostics: TiktigerDeviceDiagnostics = .shared
    ) {
        self.defaults = defaults
        self.diagnostics = diagnostics
        self.language = defaults.string(forKey: "tiktiger.language") ?? "en"
    }

    func refresh() {
        language = defaults.string(forKey: "tiktiger.language") ?? "en"
    }

    func setLanguage(_ newLanguage: String) {
        let supported = ["en", "ar", "es", "vi"]
        let next = supported.contains(newLanguage) ? newLanguage : "en"
        diagnostics.recordFeatureEvent(feature: "Translation", event: "action_started", detail: "language=\(next)")
        diagnostics.recordFeatureEvent(feature: "Translation", event: "service_called", detail: "TiktigerLocalizationService")
        language = next
        defaults.set(next, forKey: "tiktiger.language")
        diagnostics.recordFeatureEvent(feature: "Translation", event: "persistence_updated", detail: "language preference saved")
        diagnostics.recordFeatureEvent(feature: "Translation", event: "state_changed", detail: "language=\(next) direction=\(layoutDirection == .rightToLeft ? "rtl" : "ltr")")
        diagnostics.recordFeatureEvent(feature: "Translation", event: "result_success", detail: "localized resource selected")
        diagnostics.recordFeatureEvent(feature: "Translation", event: "success", detail: "localized resource selected")
    }

    func text(_ key: String) -> String {
        let selectedPath = Bundle.main.path(forResource: language, ofType: "lproj")
        let englishPath = Bundle.main.path(forResource: "en", ofType: "lproj")
        let selectedBundle = selectedPath.flatMap { Bundle(path: $0) }
        let englishBundle = englishPath.flatMap { Bundle(path: $0) }
        return selectedBundle?.localizedString(forKey: key, value: nil, table: "Localizable")
            ?? englishBundle?.localizedString(forKey: key, value: key, table: "Localizable")
            ?? key
    }
}
