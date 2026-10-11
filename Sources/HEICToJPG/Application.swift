import AppKit
import SwiftUI

@main
enum HEICToJPGApplication {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        withExtendedLifetime(delegate) { app.run() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = ConversionModel()
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        createMenu()
        showWindow()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        showWindow()
        model.enqueue(urls)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard model.isConverting else { return .terminateNow }
        let alert = NSAlert()
        alert.messageText = "Photos are still being converted"
        alert.informativeText = "Keep the app open to finish. JPGs already saved and your originals will be kept if you quit."
        alert.addButton(withTitle: "Keep converting")
        alert.addButton(withTitle: "Quit")
        return alert.runModal() == .alertFirstButtonReturn ? .terminateCancel : .terminateNow
    }

    @objc private func choosePhotos() { showWindow(); model.choosePhotos() }

    @objc private func forgetFolders() { model.forgetAuthorizedFolders() }

    @objc private func showWindow() {
        if window == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 650, height: 760),
                                  styleMask: [.titled, .closable, .miniaturizable, .resizable],
                                  backing: .buffered, defer: false)
            window.title = "HEIC to JPG"
            window.contentView = NSHostingView(rootView: ContentView(model: model))
            window.contentMinSize = NSSize(width: 570, height: 680)
            window.isReleasedWhenClosed = false
            window.setFrameAutosaveName("ConverterWindow")
            window.center()
            self.window = window
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func createMenu() {
        let menu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About HEIC to JPG", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        #if APP_STORE
        let forget = appMenu.addItem(withTitle: "Forget Saved Folder Access", action: #selector(forgetFolders), keyEquivalent: "")
        forget.target = self
        appMenu.addItem(.separator())
        #endif
        appMenu.addItem(withTitle: "Hide HEIC to JPG", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = appMenu.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit HEIC to JPG", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        menu.addItem(appItem)

        let fileItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        let open = fileMenu.addItem(withTitle: "Choose Photos…", action: #selector(choosePhotos), keyEquivalent: "o")
        open.target = self
        fileMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileItem.submenu = fileMenu
        menu.addItem(fileItem)

        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu
        menu.addItem(editItem)

        let windowItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        let show = windowMenu.addItem(withTitle: "Show Converter", action: #selector(showWindow), keyEquivalent: "1")
        show.target = self
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowItem.submenu = windowMenu
        menu.addItem(windowItem)
        NSApp.windowsMenu = windowMenu
        NSApp.mainMenu = menu
    }
}

extension AppDelegate: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(forgetFolders) { return !model.isConverting }
        return true
    }
}
