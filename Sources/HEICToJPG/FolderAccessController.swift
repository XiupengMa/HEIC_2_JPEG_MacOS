import AppKit

/// Owns a balanced set of security-scope accesses for one queued conversion.
@MainActor
final class FileAccessLease {
    private var urls: [URL] = []

    func start(_ url: URL) {
        if url.startAccessingSecurityScopedResource() { urls.append(url) }
    }

    func adoptStartedAccess(_ url: URL) { urls.append(url) }

    func finish() {
        for url in urls.reversed() { url.stopAccessingSecurityScopedResource() }
        urls.removeAll()
    }
}

/// The local build needs no extra folder picker. The App Store build requests
/// explicit permission for the containing folder, then remembers a bookmark.
@MainActor
final class FolderAccessController: NSObject, NSOpenSavePanelDelegate {
    private let defaults: UserDefaults
    private let bookmarkKey = "authorizedPhotoFolders"
    private var deniedFolders: Set<URL> = []
    private var requestedFolder: URL?

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func acquire(for source: URL) throws -> FileAccessLease? {
        let lease = FileAccessLease()
        lease.start(source)
        #if APP_STORE
        let folder = source.deletingLastPathComponent().standardizedFileURL
        if deniedFolders.contains(folder) { lease.finish(); return nil }
        do {
            if let restored = restoreAccess(to: folder) {
                // restoreAccess already began access; transfer that lifetime to the lease.
                lease.adoptStartedAccess(restored)
                return lease
            }

            let panel = NSOpenPanel()
            panel.title = "Allow JPGs in this folder"
            panel.message = "Select “\(folder.lastPathComponent)” to save JPGs beside your photos. Your choice will be remembered."
            panel.prompt = "Allow Saving"
            panel.directoryURL = folder
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.canCreateDirectories = false
            panel.allowsMultipleSelection = false
            panel.delegate = self
            requestedFolder = folder
            defer { requestedFolder = nil }

            guard panel.runModal() == .OK, let selected = panel.url else {
                deniedFolders.insert(folder)
                lease.finish()
                return nil
            }
            lease.start(selected)
            let bookmark = try selected.bookmarkData(options: .withSecurityScope,
                                                    includingResourceValuesForKeys: nil, relativeTo: nil)
            var saved = savedBookmarks
            saved[folder.path] = bookmark
            defaults.set(saved, forKey: bookmarkKey)
            return lease
        } catch {
            lease.finish()
            throw error
        }
        #else
        return lease
        #endif
    }

    func finishBatch() { deniedFolders.removeAll() }

    func forgetFolders() {
        defaults.removeObject(forKey: bookmarkKey)
        deniedFolders.removeAll()
    }

    func panel(_ sender: Any, validate url: URL) throws {
        guard let requestedFolder else { return }
        guard canonical(url) == canonical(requestedFolder) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteNoPermissionError,
                          userInfo: [NSLocalizedDescriptionKey: "Select “\(requestedFolder.lastPathComponent)” so JPGs can be saved beside the original photos."])
        }
    }

    private var savedBookmarks: [String: Data] {
        defaults.dictionary(forKey: bookmarkKey) as? [String: Data] ?? [:]
    }

    private func canonical(_ url: URL) -> URL { url.resolvingSymlinksInPath().standardizedFileURL }

    /// Returns an already-accessed URL. The caller takes ownership of its scope.
    private func restoreAccess(to folder: URL) -> URL? {
        var saved = savedBookmarks
        for (key, data) in savedBookmarks {
            var stale = false
            guard let url = try? URL(resolvingBookmarkData: data, options: [.withSecurityScope, .withoutUI],
                                    relativeTo: nil, bookmarkDataIsStale: &stale) else {
                saved.removeValue(forKey: key)
                continue
            }
            guard url.startAccessingSecurityScopedResource() else { continue }
            guard canonical(url) == canonical(folder) else {
                url.stopAccessingSecurityScopedResource()
                continue
            }
            if stale, let refreshed = try? url.bookmarkData(options: .withSecurityScope,
                                                          includingResourceValuesForKeys: nil, relativeTo: nil) {
                saved.removeValue(forKey: key)
                saved[folder.path] = refreshed
            }
            defaults.set(saved, forKey: bookmarkKey)
            return url
        }
        defaults.set(saved, forKey: bookmarkKey)
        return nil
    }
}
