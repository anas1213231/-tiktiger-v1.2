import Combine
import CryptoKit
import Darwin
import Foundation
import UIKit

struct TiktigerDeviceRuntimeEvent: Identifiable, Codable {
    let id: UUID
    let timestamp: String
    let name: String
    let state: String
    let detail: String
}

struct TiktigerDeviceSymbolEvent: Identifiable, Codable {
    let id: String
    let timestamp: String
    let state: String
    let detail: String
}

struct TiktigerFeatureAuditEvent: Identifiable, Codable {
    let id: UUID
    let timestamp: String
    let feature: String
    let event: String
    let detail: String
}

struct TiktigerDeviceMilestoneReport: Identifiable, Codable {
    var id: String { name }
    let name: String
    let state: String
    let timestamp: String?
    let detail: String?
}

struct TiktigerDeviceRuntimeSnapshot: Codable {
    let generatedAt: String
    let runtimePlatform: String
    let dylibPath: String
    let dylibSHA256: String
    let dlopenResult: String
    let lastDlError: String
    let coreVersion: String
    let appVersion: String
    let iOSVersion: String
    let deviceModelIdentifier: String
    let lastRuntimeError: String
    let milestones: [TiktigerDeviceMilestoneReport]
    let symbols: [TiktigerDeviceSymbolEvent]
    let runtimeEvents: [TiktigerDeviceRuntimeEvent]
    let loadAttempts: [String]
    let featureAudit: [TiktigerFeatureAuditEvent]
}

final class TiktigerDeviceDiagnostics: ObservableObject {
    static let shared = TiktigerDeviceDiagnostics()

    @Published private(set) var runtimeEvents: [TiktigerDeviceRuntimeEvent] = []
    @Published private(set) var symbolEvents: [TiktigerDeviceSymbolEvent] = []
    @Published private(set) var featureAuditEvents: [TiktigerFeatureAuditEvent] = []
    @Published private(set) var milestoneReports: [TiktigerDeviceMilestoneReport] = []
    @Published private(set) var loadAttempts: [String] = []
    @Published private(set) var dylibPath = ""
    @Published private(set) var dylibSHA256 = ""
    @Published private(set) var dlopenResult = "NOT ATTEMPTED"
    @Published private(set) var lastDlError = ""
    @Published private(set) var coreVersion = "UNKNOWN"
    @Published private(set) var lastRuntimeError = ""

    let appVersion: String
    let iOSVersion: String
    let deviceModelIdentifier: String

    private let timestampFormatter = ISO8601DateFormatter()
    private let rootDirectory: URL
    private let runtimeEventsURL: URL
    private let symbolsURL: URL
    private let featureEventsURL: URL
    private let consoleURL: URL
    private var consoleLines: [String] = []
    private var milestoneState: [String: TiktigerDeviceMilestoneReport] = [:]
    private var lastFeatureStatus: [String: String] = [:]

    private static let milestoneOrder = [
        "dylib_loaded",
        "initializer_executed",
        "core_started",
        "feature_registry_ready",
        "ui_registered",
        "ui_presented"
    ]

    private static let baselineFeatureStatus: [String: String] = [
        "Master Switch": "IMPLEMENTED NOT TESTED",
        "Appearance": "IMPLEMENTED NOT TESTED",
        "Translation": "IMPLEMENTED NOT TESTED",
        "Download": "PROVIDER REQUIRED",
        "Photos": "DEVICE TEST REQUIRED",
        "M4A": "DEVICE TEST REQUIRED",
        "Share": "IMPLEMENTED NOT TESTED",
        "Face ID": "DEVICE TEST REQUIRED",
        "Chats Lock": "DEVICE TEST REQUIRED",
        "Favorites Lock": "DEVICE TEST REQUIRED"
    ]

    private init() {
        let fileManager = FileManager.default
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TiktigerDiagnostics", isDirectory: true)
        try? fileManager.createDirectory(at: base, withIntermediateDirectories: true)
        rootDirectory = base
        runtimeEventsURL = base.appendingPathComponent("runtime-events.json")
        symbolsURL = base.appendingPathComponent("symbols.json")
        featureEventsURL = base.appendingPathComponent("feature-audit.json")
        consoleURL = base.appendingPathComponent("device-console.log")

        let info = Bundle.main.infoDictionary ?? [:]
        appVersion = (info["CFBundleShortVersionString"] as? String) ?? "UNKNOWN"
        iOSVersion = UIDevice.current.systemVersion
        deviceModelIdentifier = Self.currentDeviceModelIdentifier()
        loadPersistedRecords()
        rebuildMilestoneReports()
    }

    func recordRuntimeEvent(_ name: String, state: String, detail: String) {
        let event = TiktigerDeviceRuntimeEvent(
            id: UUID(),
            timestamp: timestamp(),
            name: name,
            state: state,
            detail: sanitized(detail)
        )
        appendRuntimeEvent(event)
    }

    func recordMilestone(_ name: String, state: String, detail: String) {
        let normalizedState = Self.allowedMilestoneState(state)
        let report = TiktigerDeviceMilestoneReport(
            name: name,
            state: normalizedState,
            timestamp: normalizedState == "NOT REACHED" ? nil : timestamp(),
            detail: sanitized(detail)
        )
        if let previous = milestoneState[name], previous.state == report.state {
            return
        }
        milestoneState[name] = report
        rebuildMilestoneReports()
        recordRuntimeEvent(name, state: normalizedState, detail: detail)
    }

    func recordDlopenAttempt(path: String, success: Bool, error: String) {
        let safePath = sanitized(path)
        let safeError = sanitized(error)
        let state = success ? "VERIFIED" : "FAILED"
        let detail = success ? "path=\(safePath)" : "path=\(safePath) dlerror=\(safeError)"
        loadAttempts.append("\(timestamp()): dlopen \(state) \(detail)")
        dlopenResult = success ? "SUCCEEDED" : "FAILED"
        if !safeError.isEmpty {
            lastDlError = safeError
        }
        if success {
            dylibPath = safePath
            dylibSHA256 = Self.sha256(forPath: path)
        }
        recordRuntimeEvent("dlopen", state: state, detail: detail)
        persistRecords()
    }

    func recordSymbol(name: String, found: Bool, detail: String) {
        let event = TiktigerDeviceSymbolEvent(
            id: name,
            timestamp: timestamp(),
            state: found ? "FOUND" : "FAILED",
            detail: sanitized(detail)
        )
        if let index = symbolEvents.firstIndex(where: { $0.id == name }) {
            symbolEvents[index] = event
        } else {
            symbolEvents.append(event)
        }
        recordRuntimeEvent("dlsym.\(name)", state: event.state, detail: event.detail)
        persistRecords()
    }

    func recordFeatureEvent(feature: String, event: String, detail: String = "") {
        let allowedEvents = ["action_started", "service_called", "state_changed", "persistence_updated", "registry_updated", "result_success", "result_failed", "success", "failure", "cancel", "error"]
        let normalizedEvent = allowedEvents.contains(event) ? event : "error"
        let audit = TiktigerFeatureAuditEvent(
            id: UUID(),
            timestamp: timestamp(),
            feature: sanitized(feature),
            event: normalizedEvent,
            detail: sanitized(detail)
        )
        featureAuditEvents.append(audit)
        if normalizedEvent == "result_success" || normalizedEvent == "success" {
            lastFeatureStatus[feature] = "VERIFIED"
        } else if normalizedEvent == "result_failed" || normalizedEvent == "failure" || normalizedEvent == "error" {
            lastFeatureStatus[feature] = "FAILED"
        }
        appendConsoleLine("feature=\(audit.feature) event=\(audit.event) detail=\(audit.detail)")
        persistRecords()
    }

    func setCoreVersion(_ version: String) {
        coreVersion = sanitized(version)
        recordRuntimeEvent("core_version", state: "FOUND", detail: "version=\(coreVersion)")
    }

    func setLastRuntimeError(_ message: String) {
        lastRuntimeError = sanitized(message)
        if !lastRuntimeError.isEmpty {
            recordRuntimeEvent("runtime_error", state: "FAILED", detail: lastRuntimeError)
        }
    }

    func featureStatus(for feature: String) -> String {
        if let status = lastFeatureStatus[feature] {
            return status
        }
        return Self.baselineFeatureStatus[feature] ?? "DEVICE TEST REQUIRED"
    }

    func exportRuntimeReport() throws -> [URL] {
        let snapshot = makeSnapshot()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonURL = rootDirectory.appendingPathComponent("device-runtime.json")
        let exportedConsoleURL = rootDirectory.appendingPathComponent("device-console.log")
        let markdownURL = rootDirectory.appendingPathComponent("DEVICE_RUNTIME_VERIFICATION.md")
        try encoder.encode(snapshot).write(to: jsonURL, options: .atomic)
        try consoleLines.joined(separator: "\n").appending("\n").data(using: .utf8)?.write(to: exportedConsoleURL, options: .atomic)
        try makeMarkdown(snapshot: snapshot).data(using: .utf8)?.write(to: markdownURL, options: .atomic)
        appendConsoleLine("report_export files=device-runtime.json,device-console.log,DEVICE_RUNTIME_VERIFICATION.md")
        return [jsonURL, exportedConsoleURL, markdownURL]
    }

    private func makeSnapshot() -> TiktigerDeviceRuntimeSnapshot {
        TiktigerDeviceRuntimeSnapshot(
            generatedAt: timestamp(),
            runtimePlatform: UIDevice.current.userInterfaceIdiom == .phone ? "iphone" : "ios",
            dylibPath: dylibPath,
            dylibSHA256: dylibSHA256,
            dlopenResult: dlopenResult,
            lastDlError: lastDlError,
            coreVersion: coreVersion,
            appVersion: appVersion,
            iOSVersion: iOSVersion,
            deviceModelIdentifier: deviceModelIdentifier,
            lastRuntimeError: lastRuntimeError,
            milestones: milestoneReports,
            symbols: symbolEvents,
            runtimeEvents: runtimeEvents,
            loadAttempts: loadAttempts,
            featureAudit: featureAuditEvents
        )
    }

    private func makeMarkdown(snapshot: TiktigerDeviceRuntimeSnapshot) -> String {
        var lines: [String] = []
        lines.append("# Tiktiger Device Runtime Verification")
        lines.append("")
        lines.append("> This report contains only runtime observations made by the Host. It does not mark a milestone VERIFIED from static presence alone.")
        lines.append("")
        lines.append("| Context | Value |")
        lines.append("|---|---|")
        lines.append("| App version | \(snapshot.appVersion) |")
        lines.append("| Core version | \(snapshot.coreVersion) |")
        lines.append("| iOS version | \(snapshot.iOSVersion) |")
        lines.append("| Device model identifier | \(snapshot.deviceModelIdentifier) |")
        lines.append("| Runtime platform | \(snapshot.runtimePlatform) |")
        lines.append("| Dylib path | \(snapshot.dylibPath.isEmpty ? "NONE" : snapshot.dylibPath) |")
        lines.append("| Dylib SHA-256 | \(snapshot.dylibSHA256.isEmpty ? "NOT AVAILABLE" : snapshot.dylibSHA256) |")
        lines.append("| dlopen | \(snapshot.dlopenResult) |")
        lines.append("| Last dlerror | \(snapshot.lastDlError.isEmpty ? "NONE" : snapshot.lastDlError) |")
        lines.append("| Last runtime error | \(snapshot.lastRuntimeError.isEmpty ? "NONE" : snapshot.lastRuntimeError) |")
        lines.append("")
        lines.append("## Milestones")
        lines.append("")
        lines.append("| Milestone | State | Timestamp | Detail |")
        lines.append("|---|---|---|---|")
        for item in snapshot.milestones {
            lines.append("| \(item.name) | \(item.state) | \(item.timestamp ?? "NOT REACHED") | \(item.detail ?? "NOT REACHED") |")
        }
        lines.append("")
        lines.append("## Symbols")
        lines.append("")
        lines.append("| Symbol | State | Timestamp | Detail |")
        lines.append("|---|---|---|---|")
        for item in snapshot.symbols {
            lines.append("| \(item.id) | \(item.state) | \(item.timestamp) | \(item.detail) |")
        }
        lines.append("")
        lines.append("## Feature Runtime Audit")
        lines.append("")
        lines.append("| Feature | Status |")
        lines.append("|---|---|")
        for feature in Self.baselineFeatureStatus.keys.sorted() {
            lines.append("| \(feature) | \(featureStatus(for: feature)) |")
        }
        lines.append("")
        lines.append("### Event log")
        lines.append("")
        lines.append("| Timestamp | Feature | Event | Detail |")
        lines.append("|---|---|---|---|")
        for item in snapshot.featureAudit {
            lines.append("| \(item.timestamp) | \(item.feature) | \(item.event) | \(item.detail) |")
        }
        return lines.joined(separator: "\n") + "\n"
    }

    private func appendRuntimeEvent(_ event: TiktigerDeviceRuntimeEvent) {
        runtimeEvents.append(event)
        appendConsoleLine("runtime=\(event.name) state=\(event.state) detail=\(event.detail)")
        persistRecords()
    }

    private func appendConsoleLine(_ line: String) {
        let entry = "\(timestamp()) \(sanitized(line))"
        consoleLines.append(entry)
        guard let data = (entry + "\n").data(using: .utf8) else { return }
        if FileManager.default.fileExists(atPath: consoleURL.path) {
            if let handle = try? FileHandle(forWritingTo: consoleURL) {
                try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
                try? handle.close()
            }
        } else {
            try? data.write(to: consoleURL, options: .atomic)
        }
    }

    private func rebuildMilestoneReports() {
        milestoneReports = Self.milestoneOrder.map { name in
            milestoneState[name] ?? TiktigerDeviceMilestoneReport(name: name, state: "NOT REACHED", timestamp: nil, detail: nil)
        }
    }

    private func persistRecords() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(runtimeEvents) { try? data.write(to: runtimeEventsURL, options: .atomic) }
        if let data = try? encoder.encode(symbolEvents) { try? data.write(to: symbolsURL, options: .atomic) }
        if let data = try? encoder.encode(featureAuditEvents) { try? data.write(to: featureEventsURL, options: .atomic) }
    }

    private func loadPersistedRecords() {
        if let data = try? Data(contentsOf: runtimeEventsURL),
           let value = try? JSONDecoder().decode([TiktigerDeviceRuntimeEvent].self, from: data) {
            runtimeEvents = value
        }
        if let data = try? Data(contentsOf: symbolsURL),
           let value = try? JSONDecoder().decode([TiktigerDeviceSymbolEvent].self, from: data) {
            symbolEvents = value
        }
        if let data = try? Data(contentsOf: featureEventsURL),
           let value = try? JSONDecoder().decode([TiktigerFeatureAuditEvent].self, from: data) {
            featureAuditEvents = value
            for item in value {
                if item.event == "result_success" || item.event == "success" { lastFeatureStatus[item.feature] = "VERIFIED" }
                if item.event == "result_failed" || item.event == "failure" || item.event == "error" { lastFeatureStatus[item.feature] = "FAILED" }
            }
        }
        if let data = try? Data(contentsOf: consoleURL),
           let value = String(data: data, encoding: .utf8) {
            consoleLines = value.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        }
    }

    private func timestamp() -> String {
        timestampFormatter.string(from: Date())
    }

    private func sanitized(_ value: String) -> String {
        var result = value
        result = result.replacingOccurrences(of: "Authorization:[^\\n]*", with: "Authorization:[REDACTED]", options: .regularExpression)
        result = result.replacingOccurrences(of: "Bearer\\s+[^\\s]+", with: "Bearer [REDACTED]", options: .regularExpression)
        result = result.replacingOccurrences(of: "Cookie:[^\\n]*", with: "Cookie:[REDACTED]", options: .regularExpression)
        result = result.replacingOccurrences(of: "Set-Cookie:[^\\n]*", with: "Set-Cookie:[REDACTED]", options: .regularExpression)
        return result
    }

    private static func allowedMilestoneState(_ state: String) -> String {
        ["VERIFIED", "FAILED", "NOT REACHED"].contains(state) ? state : "NOT REACHED"
    }

    private static func sha256(forPath path: String) -> String {
        guard !path.hasPrefix("@"), let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return "" }
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func currentDeviceModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineSize = MemoryLayout.size(ofValue: systemInfo.machine)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: machineSize) {
                String(cString: $0)
            }
        }
    }
}
