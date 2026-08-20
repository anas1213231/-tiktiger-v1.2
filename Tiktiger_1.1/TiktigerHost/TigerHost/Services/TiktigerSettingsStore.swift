import Combine
import Foundation
import TigerCore

@MainActor
final class TiktigerSettingsStore: ObservableObject {
    static let shared = TiktigerSettingsStore()

    @Published private(set) var isEnabled: Bool

    private let manager: TigerManager
    private let diagnostics: TiktigerDeviceDiagnostics

    private init(
        manager: TigerManager = TigerManager.shared,
        diagnostics: TiktigerDeviceDiagnostics = .shared
    ) {
        self.manager = manager
        self.diagnostics = diagnostics
        self.isEnabled = manager.isEnabled
    }

    func refresh() {
        isEnabled = manager.isEnabled
    }

    @discardableResult
    func setEnabled(_ enabled: Bool) -> Bool {
        diagnostics.recordFeatureEvent(
            feature: "Master Switch",
            event: "action_started",
            detail: enabled ? "enable requested" : "disable requested"
        )
        diagnostics.recordFeatureEvent(
            feature: "Master Switch",
            event: "service_called",
            detail: "TiktigerSettingsStore"
        )

        manager.isEnabled = enabled
        isEnabled = enabled
        diagnostics.recordFeatureEvent(
            feature: "Master Switch",
            event: "persistence_updated",
            detail: "TigerManager UserDefaults state written"
        )
        diagnostics.recordFeatureEvent(
            feature: "Master Switch",
            event: "state_changed",
            detail: enabled ? "global enabled state=true" : "global enabled state=false"
        )

        let runtime = TiktigerRuntimeCoordinator.shared
        runtime.start()
        var registryUpdated = true
        if runtime.runtimePlatform == "iphoneos" && !runtime.registeredFeatureKeys.isEmpty {
            for key in runtime.registeredFeatureKeys {
                let dependentEnabled = enabled ? manager.featureEnabled(forKey: key, defaultValue: false) : false
                if !runtime.setFeature(key, enabled: dependentEnabled) {
                    registryUpdated = false
                }
            }
        } else {
            diagnostics.recordFeatureEvent(
                feature: "Master Switch",
                event: "registry_updated",
                detail: "No device registry update required on current platform"
            )
        }

        if registryUpdated {
            diagnostics.recordFeatureEvent(
                feature: "Master Switch",
                event: "registry_updated",
                detail: "Dependent registry features synchronized"
            )
            diagnostics.recordFeatureEvent(
                feature: "Master Switch",
                event: "result_success",
                detail: "Global state and dependent features updated"
            )
            diagnostics.recordFeatureEvent(
                feature: "Master Switch",
                event: "success",
                detail: "Global state and dependent features updated"
            )
        } else {
            diagnostics.recordFeatureEvent(
                feature: "Master Switch",
                event: "result_failed",
                detail: "One or more registry features rejected the state"
            )
            diagnostics.recordFeatureEvent(
                feature: "Master Switch",
                event: "failure",
                detail: "One or more registry features rejected the state"
            )
        }
        return registryUpdated
    }

    func effectiveFeatureEnabled(for key: String, defaultValue: Bool) -> Bool {
        guard isEnabled else { return false }
        return manager.featureEnabled(forKey: key, defaultValue: defaultValue)
    }

    func storedFeatureEnabled(for key: String, defaultValue: Bool) -> Bool {
        manager.featureEnabled(forKey: key, defaultValue: defaultValue)
    }

    @discardableResult
    func setFeature(_ enabled: Bool, forKey key: String, diagnosticName: String) -> Bool {
        let featureDiagnostics = diagnostics
        featureDiagnostics.recordFeatureEvent(feature: diagnosticName, event: "action_started", detail: enabled ? "enable" : "disable")
        guard isEnabled else {
            featureDiagnostics.recordFeatureEvent(feature: diagnosticName, event: "result_failed", detail: "Master Switch is disabled")
            featureDiagnostics.recordFeatureEvent(feature: diagnosticName, event: "failure", detail: "Master Switch is disabled")
            return false
        }

        let runtime = TiktigerRuntimeCoordinator.shared
        let registryOwnsFeature = runtime.registeredFeatureKeys.contains(key)
        if registryOwnsFeature {
            guard runtime.setFeature(key, enabled: enabled) else {
                featureDiagnostics.recordFeatureEvent(feature: diagnosticName, event: "result_failed", detail: "dylib registry rejected feature state")
                featureDiagnostics.recordFeatureEvent(feature: diagnosticName, event: "failure", detail: "dylib registry rejected feature state")
                return false
            }
            featureDiagnostics.recordFeatureEvent(feature: diagnosticName, event: "registry_updated", detail: "dylib feature registry")
        }

        manager.setFeatureEnabled(enabled, forKey: key)
        featureDiagnostics.recordFeatureEvent(feature: diagnosticName, event: "persistence_updated", detail: "TigerManager UserDefaults feature state written")
        featureDiagnostics.recordFeatureEvent(feature: diagnosticName, event: "state_changed", detail: enabled ? "enabled" : "disabled")
        featureDiagnostics.recordFeatureEvent(feature: diagnosticName, event: "result_success", detail: "Feature state updated")
        featureDiagnostics.recordFeatureEvent(feature: diagnosticName, event: "success", detail: "Feature state updated")
        return true
    }
}
