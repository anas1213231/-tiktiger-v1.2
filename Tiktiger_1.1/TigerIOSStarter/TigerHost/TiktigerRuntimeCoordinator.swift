import Combine
import Foundation
import Darwin
import UIKit

struct TiktigerRuntimeSymbolStatus: Identifiable {
    let id: String
    let found: Bool
    let detail: String
    let timestamp: String
}

struct TiktigerRuntimeMilestone: Identifiable {
    let id = UUID()
    let name: String
    let state: String
    let timestamp: String
    let detail: String
}

final class TiktigerRuntimeCoordinator: ObservableObject {
    static let shared = TiktigerRuntimeCoordinator()

    @Published private(set) var dylibLoaded = false
    @Published private(set) var initializerExecuted = false
    @Published private(set) var coreStarted = false
    @Published private(set) var featureRegistryReady = false
    @Published private(set) var uiRegistered = false
    @Published private(set) var uiPresented = false
    @Published private(set) var diagnosticsJSON = "{}"
    @Published private(set) var registeredFeatureKeys: [String] = []
    @Published private(set) var symbolReports: [TiktigerRuntimeSymbolStatus] = []
    @Published private(set) var milestoneEvents: [TiktigerRuntimeMilestone] = []
    @Published private(set) var loadAttempts: [String] = []
    @Published private(set) var dylibPath = ""
    @Published private(set) var runtimePlatform = "unknown"
    @Published private(set) var lastError = ""
    @Published private(set) var attempted = false

    private var handle: UnsafeMutableRawPointer?
    private var didRegisterUI = false
    private var resolvedSymbols: [String: UnsafeMutableRawPointer] = [:]
    private let timestampFormatter = ISO8601DateFormatter()

    private typealias TTNoArg = @convention(c) () -> Void
    private typealias TTInt = @convention(c) () -> Int32
    private typealias TTString = @convention(c) () -> UnsafePointer<CChar>?
    private typealias TTSetFeature = @convention(c) (UnsafePointer<CChar>?, Int32) -> Int32
    private typealias TTFeatureCount = @convention(c) () -> UInt
    private typealias TTFeatureKeyAt = @convention(c) (UInt) -> UnsafePointer<CChar>?
    private typealias TTStage = @convention(c) (Int32) -> Void

    private let requiredSymbolNames = [
        "tt_product_name",
        "tt_version",
        "tt_runtime_initialize",
        "tt_runtime_dylib_loaded",
        "tt_runtime_initializer_executed",
        "tt_runtime_core_started",
        "tt_runtime_feature_registry_ready",
        "tt_runtime_mark_ui_registered",
        "tt_runtime_mark_ui_presented",
        "tt_runtime_ui_registered",
        "tt_runtime_ui_presented",
        "tt_runtime_diagnostics_json",
        "tt_feature_count",
        "tt_feature_key_at",
        "tt_set_feature_enabled",
        "tt_set_download_stage"
    ]

    private init() {}

    var overallState: String {
        if !attempted { return "NOT STARTED" }
        if dylibLoaded && initializerExecuted && coreStarted && featureRegistryReady && uiRegistered && uiPresented {
            return "VERIFIED"
        }
        return "FAILED"
    }

    func start() {
        attempted = true
#if targetEnvironment(simulator)
        runtimePlatform = "iphonesimulator"
        lastError = "Device-only Tiktiger.dylib load skipped on iphonesimulator"
        recordMilestone("simulator_device_load", state: "SKIPPED", detail: lastError)
        refreshState()
        return
#else
        runtimePlatform = "iphoneos"
        guard openDylib() else {
            refreshState()
            return
        }
        resolveRequiredSymbols()
        _ = callVoid(named: "tt_runtime_initialize")
        recordMilestone("initializer_call", state: initializerExecuted ? "VERIFIED" : "FAILED", detail: "Host call completed")
        refreshState()
#endif
    }

    func setDownloadStage(_ stage: Int32) {
        guard handle != nil else { return }
        guard let symbol = symbol(named: "tt_set_download_stage") else { return }
        unsafeBitCast(symbol, to: TTStage.self)(stage)
    }

    func setFeature(_ key: String, enabled: Bool) -> Bool {
        if handle == nil {
            start()
        }
        guard let symbol = symbol(named: "tt_set_feature_enabled") else {
            return false
        }
        return key.withCString { featureKey in
            unsafeBitCast(symbol, to: TTSetFeature.self)(featureKey, enabled ? 1 : 0) == 0
        }
    }

    func markUIRegistered(from view: UIView) {
        guard handle != nil,
              view.window != nil,
              view.superview != nil else { return }
        guard !didRegisterUI else { return }
        guard callVoid(named: "tt_runtime_mark_ui_registered") else { return }
        didRegisterUI = true
        recordMilestone("ui_registered", state: "VERIFIED", detail: "Host probe view entered a window hierarchy")
        refreshState()
    }

    func confirmPresented(from view: UIView) {
        guard handle != nil,
              didRegisterUI,
              view.window != nil,
              view.superview != nil,
              !view.bounds.isEmpty else { return }
        guard callVoid(named: "tt_runtime_mark_ui_presented") else { return }
        recordMilestone("ui_presented", state: "VERIFIED", detail: "Host probe view has a window, superview, and non-empty bounds")
        refreshState()
    }

    private func openDylib() -> Bool {
        if handle != nil { return true }

        var candidates: [String] = []
        if let privateFrameworksPath = Bundle.main.privateFrameworksPath {
            candidates.append(URL(fileURLWithPath: privateFrameworksPath)
                .appendingPathComponent("Tiktiger.dylib").path)
        }
        if let frameworksPath = Bundle.main.path(forResource: "Tiktiger", ofType: "dylib", inDirectory: "Frameworks") {
            candidates.append(frameworksPath)
        }
        candidates.append("@rpath/Tiktiger.dylib")

        var uniqueCandidates: [String] = []
        for candidate in candidates where !uniqueCandidates.contains(candidate) {
            uniqueCandidates.append(candidate)
        }

        for candidate in uniqueCandidates {
            _ = dlerror()
            let loaded = candidate.withCString { path in
                dlopen(path, RTLD_NOW | RTLD_GLOBAL)
            }
            if let loaded {
                handle = loaded
                dylibPath = candidate
                let detail = "FOUND path=\(candidate)"
                loadAttempts.append("\(timestamp()): \(detail)")
                recordMilestone("dylib_loaded", state: "VERIFIED", detail: detail)
                lastError = ""
                // Intentionally no dlclose: the singleton retains this handle for app lifetime.
                return true
            }
            let error = takeDlError()
            let detail = error.isEmpty ? "FAILED path=\(candidate)" : "FAILED path=\(candidate) dlerror=\(error)"
            loadAttempts.append("\(timestamp()): \(detail)")
        }

        lastError = loadAttempts.last ?? "Tiktiger.dylib load failed"
        recordMilestone("dylib_loaded", state: "FAILED", detail: lastError)
        return false
    }

    private func resolveRequiredSymbols() {
        for name in requiredSymbolNames {
            _ = symbol(named: name)
        }
    }

    private func takeDlError() -> String {
        guard let pointer = dlerror() else { return "" }
        return String(cString: pointer)
    }

    private func symbol(named name: String) -> UnsafeMutableRawPointer? {
        if let cached = resolvedSymbols[name] { return cached }
        guard let handle else {
            recordSymbol(name: name, found: false, detail: "FAILED no dlopen handle")
            return nil
        }
        _ = dlerror()
        let pointer = name.withCString { symbolName in
            dlsym(handle, symbolName)
        }
        let error = takeDlError()
        if let pointer {
            resolvedSymbols[name] = pointer
            recordSymbol(name: name, found: true, detail: "FOUND dlsym")
            return pointer
        }
        recordSymbol(name: name, found: false, detail: error.isEmpty ? "FAILED dlsym returned NULL" : "FAILED dlerror=\(error)")
        return nil
    }

    @discardableResult
    private func callVoid(named name: String) -> Bool {
        guard let symbol = symbol(named: name) else {
            lastError = "Missing runtime symbol: \(name)"
            return false
        }
        unsafeBitCast(symbol, to: TTNoArg.self)()
        return true
    }

    private func intValue(named name: String) -> Bool {
        guard let symbol = symbol(named: name) else { return false }
        return unsafeBitCast(symbol, to: TTInt.self)() == 1
    }

    private func refreshState() {
        dylibLoaded = handle != nil && intValue(named: "tt_runtime_dylib_loaded")
        initializerExecuted = intValue(named: "tt_runtime_initializer_executed")
        coreStarted = intValue(named: "tt_runtime_core_started")
        featureRegistryReady = intValue(named: "tt_runtime_feature_registry_ready")
        uiRegistered = intValue(named: "tt_runtime_ui_registered")
        uiPresented = intValue(named: "tt_runtime_ui_presented")

        if let countSymbol = symbol(named: "tt_feature_count"),
           let keySymbol = symbol(named: "tt_feature_key_at") {
            let count = unsafeBitCast(countSymbol, to: TTFeatureCount.self)()
            let keyAt = unsafeBitCast(keySymbol, to: TTFeatureKeyAt.self)
            registeredFeatureKeys = (0..<count).compactMap { index in
                guard let pointer = keyAt(index) else { return nil }
                return String(cString: pointer)
            }
        }

        if let symbol = symbol(named: "tt_runtime_diagnostics_json") {
            let function = unsafeBitCast(symbol, to: TTString.self)
            if let pointer = function() {
                diagnosticsJSON = String(cString: pointer)
            }
        }
    }

    private func timestamp() -> String {
        timestampFormatter.string(from: Date())
    }

    private func recordSymbol(name: String, found: Bool, detail: String) {
        let report = TiktigerRuntimeSymbolStatus(id: name, found: found, detail: detail, timestamp: timestamp())
        if let index = symbolReports.firstIndex(where: { $0.id == name }) {
            symbolReports[index] = report
        } else {
            symbolReports.append(report)
        }
    }

    private func recordMilestone(_ name: String, state: String, detail: String) {
        milestoneEvents.append(TiktigerRuntimeMilestone(name: name, state: state, timestamp: timestamp(), detail: detail))
    }
}
