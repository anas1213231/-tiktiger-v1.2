import Combine
import Foundation
import Darwin

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
    @Published private(set) var lastError = ""
    @Published private(set) var attempted = false

    private var handle: UnsafeMutableRawPointer?
    private var didRegisterUI = false

    private typealias TTNoArg = @convention(c) () -> Void
    private typealias TTInt = @convention(c) () -> Int32
    private typealias TTString = @convention(c) () -> UnsafePointer<CChar>?
    private typealias TTSetFeature = @convention(c) (UnsafePointer<CChar>?, Int32) -> Int32
    private typealias TTFeatureCount = @convention(c) () -> UInt
    private typealias TTFeatureKeyAt = @convention(c) (UInt) -> UnsafePointer<CChar>?
    private typealias TTStage = @convention(c) (Int32) -> Void

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
        guard openDylib() else {
            refreshState()
            return
        }

        callVoid(named: "tt_runtime_initialize")
        if !didRegisterUI {
            callVoid(named: "tt_runtime_mark_ui_registered")
            didRegisterUI = true
        }
        refreshState()
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

    func markPresented() {
        guard handle != nil else {
            refreshState()
            return
        }
        callVoid(named: "tt_runtime_mark_ui_presented")
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

        for candidate in candidates {
            let loaded = candidate.withCString { path in
                dlopen(path, RTLD_NOW | RTLD_GLOBAL)
            }
            if let loaded {
                handle = loaded
                lastError = ""
                return true
            }
        }

        lastError = "Tiktiger.dylib was not loadable from the host app Frameworks path"
        return false
    }

    private func symbol(named name: String) -> UnsafeMutableRawPointer? {
        guard let handle else { return nil }
        return name.withCString { symbolName in
            dlsym(handle, symbolName)
        }
    }

    private func callVoid(named name: String) {
        guard let symbol = symbol(named: name) else {
            lastError = "Missing runtime symbol: \(name)"
            return
        }
        unsafeBitCast(symbol, to: TTNoArg.self)()
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
}
