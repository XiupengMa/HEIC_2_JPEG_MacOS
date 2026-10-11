import AppKit
import SwiftUI
import UniformTypeIdentifiers
import ConversionCore

struct ConversionItem: Identifiable {
    enum Status {
        case queued, converting, saved(URL), failed(String), cancelled
    }
    let id = UUID()
    let source: URL
    var status: Status = .queued
}

@MainActor
final class ConversionModel: ObservableObject {
    @Published private(set) var items: [ConversionItem] = []
    @Published private(set) var isConverting = false
    @Published var dropError: String?
    @Published var quality: Double {
        didSet { UserDefaults.standard.set(quality, forKey: "jpegQuality") }
    }
    @Published var preserveMetadata: Bool {
        didSet { UserDefaults.standard.set(preserveMetadata, forKey: "preserveMetadata") }
    }

    private struct Job {
        let id: UUID
        let source: URL
        let accessURL: URL
        let options: ConversionOptions
    }
    private var pending: [Job] = []
    private var activeSources: Set<URL> = []
    private let folderAccess = FolderAccessController()

    init() {
        UserDefaults.standard.register(defaults: ["jpegQuality": 0.9, "preserveMetadata": true])
        let savedQuality = UserDefaults.standard.double(forKey: "jpegQuality")
        quality = [0.8, 0.9, 1.0].contains(savedQuality) ? savedQuality : 0.9
        preserveMetadata = UserDefaults.standard.bool(forKey: "preserveMetadata")
    }

    var outputs: [URL] {
        items.compactMap { if case .saved(let url) = $0.status { return url }; return nil }
    }
    var failureCount: Int {
        items.filter { if case .failed = $0.status { return true }; return false }.count
    }
    var finishedCount: Int {
        items.filter { switch $0.status { case .queued, .converting: return false; default: return true } }.count
    }
    var hasPending: Bool { items.contains { if case .queued = $0.status { return true }; return false } }

    func choosePhotos() {
        let panel = NSOpenPanel()
        panel.title = "Choose HEIC photos"
        panel.message = "JPG copies will be saved beside the originals."
        panel.prompt = "Convert to JPG"
        panel.allowedContentTypes = [.heic, .heif]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK { enqueue(panel.urls) }
    }

    func enqueue(_ urls: [URL]) {
        let options = ConversionOptions(quality: quality, preserveMetadata: preserveMetadata)
        for url in urls {
            let source = url.standardizedFileURL
            guard !activeSources.contains(source) else { continue }
            var item = ConversionItem(source: source)
            guard source.isFileURL, PhotoConverter.supportedExtensions.contains(source.pathExtension.lowercased()) else {
                item.status = .failed(ConversionError.unsupportedFile.localizedDescription)
                items.append(item)
                continue
            }
            items.append(item)
            pending.append(Job(id: item.id, source: source, accessURL: url, options: options))
            activeSources.insert(source)
        }
        guard !isConverting, !pending.isEmpty else { return }
        isConverting = true
        Task { await processQueue() }
    }

    private func processQueue() async {
        while !pending.isEmpty {
            let job = pending.removeFirst()
            update(job.id, to: .converting)
            // Opening a photo grants access to the photo, not necessarily the
            // containing folder where its JPG will be created.
            let lease: FileAccessLease
            do {
                guard let access = try folderAccess.acquire(for: job.accessURL) else {
                    update(job.id, to: .cancelled)
                    activeSources.remove(job.source)
                    continue
                }
                lease = access
            } catch {
                update(job.id, to: .failed("Couldn’t access the photo’s folder: \(error.localizedDescription)"))
                activeSources.remove(job.source)
                continue
            }
            // Serial background work keeps the UI responsive and limits memory use for large batches.
            let result = await Task.detached(priority: .userInitiated) {
                Result { try PhotoConverter.convert(job.source, options: job.options) }
            }.value
            lease.finish()
            switch result {
            case .success(let result): update(job.id, to: .saved(result.outputURL))
            case .failure(let error): update(job.id, to: .failed(error.localizedDescription))
            }
            activeSources.remove(job.source)
        }
        isConverting = false
        folderAccess.finishBatch()
    }

    private func update(_ id: UUID, to status: ConversionItem.Status) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].status = status
    }

    func stopAfterCurrentPhoto() {
        for job in pending {
            update(job.id, to: .cancelled)
            activeSources.remove(job.source)
        }
        pending.removeAll()
    }

    func clear() {
        guard !isConverting else { return }
        items.removeAll()
    }

    func revealOutputs() { NSWorkspace.shared.activateFileViewerSelecting(outputs) }

    func forgetAuthorizedFolders() {
        guard !isConverting else { return }
        folderAccess.forgetFolders()
    }

    func acceptDrop(_ providers: [NSItemProvider]) -> Bool {
        let files = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
        guard !files.isEmpty else { return false }
        Task {
            var urls: [URL] = []
            var unreadableCount = 0
            for provider in files {
                let url: URL? = await withCheckedContinuation { continuation in
                    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                        if let data = item as? Data {
                            continuation.resume(returning: URL(dataRepresentation: data, relativeTo: nil))
                        } else if let url = item as? URL {
                            continuation.resume(returning: url)
                        } else {
                            continuation.resume(returning: nil)
                        }
                    }
                }
                if let url { urls.append(url) } else { unreadableCount += 1 }
            }
            enqueue(urls)
            if unreadableCount > 0 { dropError = "Some dropped files couldn’t be opened. Try selecting them with Choose photos."
            }
        }
        return true
    }
}
