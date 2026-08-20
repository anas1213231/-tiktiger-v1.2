import SwiftUI
import Combine
import Foundation
import AVFoundation
import Photos

protocol TiktigerMediaProvider {
    var name: String { get }
    func request(for url: URL) throws -> URLRequest
}

enum TiktigerMediaProviderError: LocalizedError {
    case providerRequired
    case invalidURL
    case httpsRequired
    case hostMissing
    case unsupportedMediaType
    case noAudioTrack
    case exporterUnavailable
    case audioExportFailed
    case photoPermissionDenied
    case photoSaveFailed
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .providerRequired:
            return "PROVIDER REQUIRED: اربط مزود وسائط مصرحًا قبل استخدام resolver."
        case .invalidURL:
            return "Invalid URL"
        case .httpsRequired:
            return "HTTPS is required"
        case .hostMissing:
            return "URL host is missing"
        case .unsupportedMediaType:
            return "Unsupported media type"
        case .noAudioTrack:
            return "No audio track found"
        case .exporterUnavailable:
            return "Audio exporter unavailable"
        case .audioExportFailed:
            return "Audio extraction failed"
        case .photoPermissionDenied:
            return "Photos permission denied"
        case .photoSaveFailed:
            return "Photo Library save failed"
        case .httpStatus(let code):
            return "Server returned HTTP \(code)"
        }
    }
}

struct TiktigerDirectHTTPSProvider: TiktigerMediaProvider {
    let name = "User-supplied Direct HTTPS URL"

    func request(for url: URL) throws -> URLRequest {
        guard url.scheme?.lowercased() == "https" else {
            throw TiktigerMediaProviderError.httpsRequired
        }
        guard let host = url.host, !host.isEmpty else {
            throw TiktigerMediaProviderError.hostMissing
        }
        var request = URLRequest(url: url, timeoutInterval: 60)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return request
    }
}

struct TiktigerDownloadRecord: Identifiable, Codable {
    let id: UUID
    let displayURL: String
    let mode: String
    let filename: String
    let date: Date

    var modeLabel: String {
        mode == "audio" ? "Audio M4A" : "Video / Image"
    }
}

@MainActor
final class TiktigerMediaDownloadService: ObservableObject {
    @Published var stage = "Idle"
    @Published var photoStatus = "Not requested"
    @Published var isBusy = false
    @Published var stateColor = Color.secondary
    @Published var lastFileURL: URL?
    @Published var lastError: String?
    @Published private(set) var history: [TiktigerDownloadRecord] = []

    let provider: TiktigerMediaProvider
    private var downloadTask: Task<Void, Never>?
    private var activeExportSession: AVAssetExportSession?
    private var lastRetryURL: String?
    private let historyKey = "tiktiger.download.history"

    init(provider: TiktigerMediaProvider = TiktigerDirectHTTPSProvider()) {
        self.provider = provider
        self.history = Self.loadHistory(forKey: historyKey)
    }

    var canRetry: Bool {
        !isBusy && lastRetryURL != nil
    }

    func download(urlString: String, mode: String) {
        let diagnostics = TiktigerDeviceDiagnostics.shared
        let feature = mode == "audio" ? "M4A" : "Download"
        diagnostics.recordFeatureEvent(feature: feature, event: "action_started", detail: "direct HTTPS download requested")
        diagnostics.recordFeatureEvent(feature: feature, event: "service_called", detail: "TiktigerMediaDownloadService")
        cancel(silent: true)
        lastError = nil
        lastFileURL = nil
        isBusy = true
        stateColor = .orange
        updateStage("Validating URL", runtimeStage: 1)

        downloadTask = Task { [weak self] in
            guard let self = self else { return }
            await self.performDownload(urlString: urlString, mode: mode)
        }
    }

    func retryLast() {
        guard let retryURL = lastRetryURL, let record = history.first else {
            TiktigerDeviceDiagnostics.shared.recordFeatureEvent(feature: "Download", event: "result_failed", detail: "No retryable download")
            return
        }
        TiktigerDeviceDiagnostics.shared.recordFeatureEvent(feature: "Download", event: "action_started", detail: "retry requested")
        TiktigerDeviceDiagnostics.shared.recordFeatureEvent(feature: "Download", event: "service_called", detail: "retryLast")
        download(urlString: retryURL, mode: record.mode)
    }

    func cancel() {
        TiktigerDeviceDiagnostics.shared.recordFeatureEvent(feature: "Download", event: "action_started", detail: "cancel requested")
        cancel(silent: false)
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    private func cancel(silent: Bool) {
        downloadTask?.cancel()
        downloadTask = nil
        activeExportSession?.cancelExport()
        activeExportSession = nil
        guard !silent, isBusy else { return }
        isBusy = false
        updateStage("Cancelled", runtimeStage: 7)
        stateColor = .orange
        TiktigerDeviceDiagnostics.shared.recordFeatureEvent(feature: "Download", event: "result_success", detail: "cancelled")
    }

    private func performDownload(urlString: String, mode: String) async {
        var destinationURL: URL?
        defer {
            if let destinationURL = destinationURL {
                try? FileManager.default.removeItem(at: destinationURL)
            }
        }
        do {
            guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                throw TiktigerMediaProviderError.invalidURL
            }
            let request = try provider.request(for: url)
            try Task.checkCancellation()
            updateStage("Downloading", runtimeStage: 2)

            let (temporaryURL, response) = try await URLSession.shared.download(for: request)
            try Task.checkCancellation()

            if let httpResponse = response as? HTTPURLResponse,
               !(200..<300).contains(httpResponse.statusCode) {
                throw TiktigerMediaProviderError.httpStatus(httpResponse.statusCode)
            }

            let mime = response.mimeType?.lowercased() ?? ""
            let extensionName = fileExtension(for: response, url: url)
            let isVideo = mime.hasPrefix("video/") || ["mp4", "mov", "m4v", "avi"].contains(extensionName.lowercased())
            let isImage = mime.hasPrefix("image/") || ["png", "jpg", "jpeg", "heic"].contains(extensionName.lowercased())
            let isAudio = mime.hasPrefix("audio/") || ["m4a", "mp3", "wav", "aac"].contains(extensionName.lowercased())
            if mode == "audio" {
                guard mime.isEmpty || isVideo || isAudio else {
                    throw TiktigerMediaProviderError.unsupportedMediaType
                }
            } else {
                guard mime.isEmpty || isVideo || isImage else {
                    throw TiktigerMediaProviderError.unsupportedMediaType
                }
            }

            updateStage("Validating file", runtimeStage: 1)
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent("Tiktiger-\(UUID().uuidString).\(extensionName)")
            destinationURL = destination
            try FileManager.default.copyItem(at: temporaryURL, to: destination)
            try? FileManager.default.removeItem(at: temporaryURL)

            if mode == "audio" {
                let output = try await extractAudio(from: destination)
                lastFileURL = output
                updateStage("Audio ready", runtimeStage: 5)
                TiktigerDeviceDiagnostics.shared.recordFeatureEvent(feature: "M4A", event: "result_success", detail: "AVAssetExportSession created \(output.lastPathComponent)")
                photoStatus = "Ready to share"
                stateColor = .green
                isBusy = false
                recordSuccess(url: url, mode: mode, filename: output.lastPathComponent)
            } else {
                try await saveToPhotos(destination, isVideo: isVideo)
                updateStage("Completed", runtimeStage: 5)
                TiktigerDeviceDiagnostics.shared.recordFeatureEvent(feature: "Download", event: "result_success", detail: "media downloaded")
                photoStatus = "Saved"
                stateColor = .green
                isBusy = false
                recordSuccess(url: url, mode: mode, filename: destination.lastPathComponent)
            }
            downloadTask = nil
        } catch is CancellationError {
            isBusy = false
            updateStage("Cancelled", runtimeStage: 7)
            stateColor = .orange
            downloadTask = nil
            TiktigerDeviceDiagnostics.shared.recordFeatureEvent(feature: mode == "audio" ? "M4A" : "Download", event: "result_success", detail: "cancelled")
        } catch {
            TiktigerDeviceDiagnostics.shared.recordFeatureEvent(feature: mode == "audio" ? "M4A" : "Download", event: "error", detail: error.localizedDescription)
            fail(error.localizedDescription, feature: mode == "audio" ? "M4A" : "Download")
        }
    }

    private func extractAudio(from videoURL: URL) async throws -> URL {
        TiktigerDeviceDiagnostics.shared.recordFeatureEvent(feature: "M4A", event: "service_called", detail: "AVAssetExportSession")
        try Task.checkCancellation()
                    updateStage("Extracting Audio", runtimeStage: 3)

        let asset = AVAsset(url: videoURL)
        guard !asset.tracks(withMediaType: .audio).isEmpty else {
            try? FileManager.default.removeItem(at: videoURL)
            throw TiktigerMediaProviderError.noAudioTrack
        }
        let output = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TiktigerAudio-\(UUID().uuidString).m4a")
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            try? FileManager.default.removeItem(at: videoURL)
            throw TiktigerMediaProviderError.exporterUnavailable
        }
        activeExportSession = exporter
        exporter.outputURL = output
        exporter.outputFileType = .m4a
        exporter.shouldOptimizeForNetworkUse = true

        return try await withCheckedThrowingContinuation { continuation in
            exporter.exportAsynchronously { [weak self] in
                Task { @MainActor in
                    self?.activeExportSession = nil
                    guard exporter.status == .completed else {
                        continuation.resume(throwing: exporter.error ?? TiktigerMediaProviderError.audioExportFailed)
                        return
                    }
                    continuation.resume(returning: output)
                }
            }
        }
    }

    private func saveToPhotos(_ fileURL: URL, isVideo: Bool) async throws {
        TiktigerDeviceDiagnostics.shared.recordFeatureEvent(feature: "Photos", event: "service_called", detail: "PHPhotoLibrary")
        photoStatus = "Requesting"
        let status = await requestPhotoAuthorization()
        guard status == .authorized || status == .limited else {
            photoStatus = "Permission denied"
            TiktigerDeviceDiagnostics.shared.recordFeatureEvent(feature: "Photos", event: "result_failed", detail: "Photo permission denied")
            throw TiktigerMediaProviderError.photoPermissionDenied
        }

        try Task.checkCancellation()
        updateStage("Saving to Photos", runtimeStage: 4)
        photoStatus = "Saving"
        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: isVideo ? .video : .photo, fileURL: fileURL, options: nil)
            }) { success, error in
                if success {
                    TiktigerDeviceDiagnostics.shared.recordFeatureEvent(feature: "Photos", event: "result_success", detail: "PHAssetCreationRequest completed")
                    continuation.resume()
                } else {
                    let detail = error?.localizedDescription ?? "Photo Library save failed"
                    TiktigerDeviceDiagnostics.shared.recordFeatureEvent(feature: "Photos", event: "result_failed", detail: detail)
                    continuation.resume(throwing: error ?? TiktigerMediaProviderError.photoSaveFailed)
                }
            }
        }
    }

    private func requestPhotoAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
    }

    private func fileExtension(for response: URLResponse, url: URL) -> String {
        if let type = response.mimeType?.lowercased() {
            if type.contains("png") { return "png" }
            if type.contains("jpeg") || type.contains("jpg") { return "jpg" }
            if type.contains("quicktime") { return "mov" }
            if type.contains("mp4") { return "mp4" }
            if type.contains("mpeg") { return "mp4" }
            if type.contains("audio") { return "m4a" }
        }
        let candidate = url.pathExtension
        return candidate.isEmpty ? "mp4" : candidate.replacingOccurrences(of: "/", with: "_")
    }

    private func recordSuccess(url: URL, mode: String, filename: String) {
        lastRetryURL = url.absoluteString
        let record = TiktigerDownloadRecord(id: UUID(), displayURL: sanitizedDisplayURL(for: url), mode: mode, filename: filename, date: Date())
        history.insert(record, at: 0)
        history = Array(history.prefix(20))
        saveHistory()
    }

    private func sanitizedDisplayURL(for url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return "https://[redacted]"
        }
        components.query = nil
        components.fragment = nil
        return components.string ?? "https://[redacted]"
    }

    private func updateStage(_ value: String, runtimeStage: Int32) {
        stage = value
        TiktigerRuntimeCoordinator.shared.setDownloadStage(runtimeStage)
    }

    private func fail(_ message: String, feature: String = "Download") {
        lastError = message
        TiktigerDeviceDiagnostics.shared.recordFeatureEvent(feature: feature, event: "result_failed", detail: message)
        updateStage(message, runtimeStage: 6)
        stateColor = .red
        isBusy = false
        downloadTask = nil
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }

    private static func loadHistory(forKey key: String) -> [TiktigerDownloadRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let records = try? JSONDecoder().decode([TiktigerDownloadRecord].self, from: data) else {
            return []
        }
        return records
    }
}
