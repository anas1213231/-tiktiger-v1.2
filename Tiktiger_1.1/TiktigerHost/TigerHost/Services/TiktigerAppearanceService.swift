import Combine
import Foundation
import SwiftUI

@MainActor
final class TiktigerAppearanceService: ObservableObject {
    enum Mode: String, CaseIterable, Identifiable, Hashable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    static let shared = TiktigerAppearanceService()

    @Published private(set) var mode: Mode

    private let defaults: UserDefaults
    private let diagnostics: TiktigerDeviceDiagnostics

    private init(
        defaults: UserDefaults = .standard,
        diagnostics: TiktigerDeviceDiagnostics = .shared
    ) {
        self.defaults = defaults
        self.diagnostics = diagnostics
        self.mode = Mode(rawValue: defaults.string(forKey: "tiktiger.appearance.mode") ?? Mode.dark.rawValue) ?? .dark
    }

    func refresh() {
        mode = Mode(rawValue: defaults.string(forKey: "tiktiger.appearance.mode") ?? Mode.dark.rawValue) ?? .dark
    }

    func setMode(_ newMode: Mode) {
        diagnostics.recordFeatureEvent(feature: "Appearance", event: "action_started", detail: "theme=\(newMode.rawValue)")
        diagnostics.recordFeatureEvent(feature: "Appearance", event: "service_called", detail: "TiktigerAppearanceService")
        mode = newMode
        defaults.set(newMode.rawValue, forKey: "tiktiger.appearance.mode")
        diagnostics.recordFeatureEvent(feature: "Appearance", event: "persistence_updated", detail: "theme preference saved")
        diagnostics.recordFeatureEvent(feature: "Appearance", event: "state_changed", detail: "theme=\(newMode.rawValue)")
        diagnostics.recordFeatureEvent(feature: "Appearance", event: "result_success", detail: "theme applied to Root environment")
        diagnostics.recordFeatureEvent(feature: "Appearance", event: "success", detail: "theme applied to Root environment")
    }
}
