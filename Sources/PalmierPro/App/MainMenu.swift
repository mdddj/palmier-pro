import AppKit

/// Builds the application main menu with keyboard shortcuts.
/// Called from AppDelegate to wire shortcuts into the responder chain.
@MainActor
enum MainMenuBuilder {

    static func buildMenu() -> NSMenu {
        let mainMenu = NSMenu()
        mainMenu.addItem(appMenu())
        mainMenu.addItem(fileMenu())
        mainMenu.addItem(editMenu())
        mainMenu.addItem(viewMenu())
        mainMenu.addItem(helpMenu())
        return mainMenu
    }

    // MARK: - App menu

    private static func appMenu() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: loc("Palmier Pro"))
        menu.addItem(withTitle: loc("About Palmier Pro"), action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        let updatesItem = NSMenuItem(title: loc("Check for Updates…"), action: #selector(Updater.checkForUpdates(_:)), keyEquivalent: "")
        updatesItem.target = Updater.shared
        menu.addItem(updatesItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: loc("Settings…"), action: #selector(AppDelegate.showSettings(_:)), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: loc("Quit Palmier Pro"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.submenu = menu
        return item
    }

    // MARK: - File menu

    private static func fileMenu() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: loc("File"))
        let newItem = menu.addItem(withTitle: loc("New"), action: #selector(AppDelegate.newProject(_:)), keyEquivalent: "n")
        newItem.target = NSApp.delegate
        let newFolderItem = NSMenuItem(title: loc("New Folder"), action: #selector(EditorActions.newMediaFolder(_:)), keyEquivalent: "n")
        newFolderItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(newFolderItem)
        let openItem = menu.addItem(withTitle: loc("Open…"), action: #selector(AppDelegate.openProject(_:)), keyEquivalent: "o")
        openItem.target = NSApp.delegate
        menu.addItem(.separator())
        menu.addItem(withTitle: loc("Save"), action: #selector(NSDocument.save(_:)), keyEquivalent: "s")
        menu.addItem(withTitle: loc("Save As…"), action: #selector(NSDocument.saveAs(_:)), keyEquivalent: "S")
        menu.addItem(.separator())

        let importItem = NSMenuItem(title: loc("Import Media…"), action: #selector(EditorActions.importMedia(_:)), keyEquivalent: "i")
        importItem.keyEquivalentModifierMask = [.command]
        menu.addItem(importItem)

        menu.addItem(.separator())

        let exportItem = NSMenuItem(title: loc("Export…"), action: #selector(EditorActions.showExport(_:)), keyEquivalent: "e")
        exportItem.keyEquivalentModifierMask = [.command]
        menu.addItem(exportItem)

        item.submenu = menu
        return item
    }

    // MARK: - Edit menu

    private static func editMenu() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: loc("Edit"))
        menu.addItem(withTitle: loc("Undo"), action: Selector(("undo:")), keyEquivalent: "z")
        menu.addItem(withTitle: loc("Redo"), action: Selector(("redo:")), keyEquivalent: "Z")
        menu.addItem(.separator())
        menu.addItem(withTitle: loc("Cut"), action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        menu.addItem(withTitle: loc("Copy"), action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        menu.addItem(withTitle: loc("Paste"), action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        menu.addItem(withTitle: loc("Select All"), action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        menu.addItem(.separator())

        let selectForwardTrackItem = NSMenuItem(title: loc("Select Forward on Track"), action: #selector(EditorActions.selectForwardOnTrack(_:)), keyEquivalent: "a")
        selectForwardTrackItem.keyEquivalentModifierMask = []
        menu.addItem(selectForwardTrackItem)

        let selectForwardAllItem = NSMenuItem(title: loc("Select Forward on All Tracks"), action: #selector(EditorActions.selectForwardOnAllTracks(_:)), keyEquivalent: "a")
        selectForwardAllItem.keyEquivalentModifierMask = [.shift]
        menu.addItem(selectForwardAllItem)

        menu.addItem(.separator())

        let splitItem = NSMenuItem(title: loc("Split at Playhead"), action: #selector(EditorActions.splitAtPlayhead(_:)), keyEquivalent: "k")
        splitItem.keyEquivalentModifierMask = [.command]
        menu.addItem(splitItem)

        let trimStartItem = NSMenuItem(title: loc("Trim Start to Playhead"), action: #selector(EditorActions.trimStartToPlayhead(_:)), keyEquivalent: "q")
        trimStartItem.keyEquivalentModifierMask = []
        menu.addItem(trimStartItem)

        let trimEndItem = NSMenuItem(title: loc("Trim End to Playhead"), action: #selector(EditorActions.trimEndToPlayhead(_:)), keyEquivalent: "w")
        trimEndItem.keyEquivalentModifierMask = []
        menu.addItem(trimEndItem)

        menu.addItem(.separator())

        let deleteItem = NSMenuItem(title: loc("Delete"), action: #selector(EditorActions.deleteSelectedClips(_:)), keyEquivalent: "\u{8}") // backspace
        deleteItem.keyEquivalentModifierMask = []
        menu.addItem(deleteItem)

        let rippleDeleteItem = NSMenuItem(title: loc("Ripple Delete"), action: #selector(EditorActions.rippleDeleteSelected(_:)), keyEquivalent: "\u{8}") // backspace
        rippleDeleteItem.keyEquivalentModifierMask = [.shift]
        menu.addItem(rippleDeleteItem)

        item.submenu = menu
        return item
    }

    // MARK: - View menu

    private static func viewMenu() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: loc("View"))

        let mediaItem = NSMenuItem(title: loc("Media Panel"), action: #selector(EditorActions.toggleMediaPanel(_:)), keyEquivalent: "0")
        mediaItem.keyEquivalentModifierMask = [.command]
        menu.addItem(mediaItem)

        let inspectorItem = NSMenuItem(title: loc("Inspector"), action: #selector(EditorActions.toggleInspectorPanel(_:)), keyEquivalent: "0")
        inspectorItem.keyEquivalentModifierMask = [.command, .option]
        menu.addItem(inspectorItem)

        let agentItem = NSMenuItem(title: loc("Agent Panel"), action: #selector(EditorActions.toggleAgentPanel(_:)), keyEquivalent: "a")
        agentItem.keyEquivalentModifierMask = [.command, .option]
        menu.addItem(agentItem)

        menu.addItem(.separator())

        let maximizeItem = NSMenuItem(title: loc("Maximize Focused Panel"), action: #selector(EditorActions.toggleMaximizePanel(_:)), keyEquivalent: "`")
        maximizeItem.keyEquivalentModifierMask = []
        menu.addItem(maximizeItem)

        menu.addItem(.separator())
        menu.addItem(layoutSubmenuItem())
        menu.addItem(.separator())
        menu.addItem(withTitle: loc("Enter Full Screen"), action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        item.submenu = menu
        return item
    }

    private static func layoutSubmenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: loc("Layout"), action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: loc("Layout"))

        let defaultItem = NSMenuItem(title: loc(LayoutPreset.default.label), action: #selector(EditorActions.setLayoutDefault(_:)), keyEquivalent: String(LayoutPreset.default.shortcutKey))
        defaultItem.keyEquivalentModifierMask = [.command]
        submenu.addItem(defaultItem)

        let mediaItem = NSMenuItem(title: loc(LayoutPreset.media.label), action: #selector(EditorActions.setLayoutMedia(_:)), keyEquivalent: String(LayoutPreset.media.shortcutKey))
        mediaItem.keyEquivalentModifierMask = [.command]
        submenu.addItem(mediaItem)

        let verticalItem = NSMenuItem(title: loc(LayoutPreset.vertical.label), action: #selector(EditorActions.setLayoutVertical(_:)), keyEquivalent: String(LayoutPreset.vertical.shortcutKey))
        verticalItem.keyEquivalentModifierMask = [.command]
        submenu.addItem(verticalItem)

        item.submenu = submenu
        return item
    }

    // MARK: - Help menu

    private static func helpMenu() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: loc("Help"))
        menu.addItem(withTitle: loc("Tutorial"), action: #selector(AppDelegate.showTutorial(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: loc("Keyboard Shortcuts"), action: #selector(AppDelegate.showKeyboardShortcuts(_:)), keyEquivalent: "?")
        menu.addItem(withTitle: loc("MCP Instructions"), action: #selector(AppDelegate.showMCPInstructions(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: loc("Send Feedback…"), action: #selector(AppDelegate.showFeedback(_:)), keyEquivalent: "")
        item.submenu = menu
        return item
    }
}

/// Actions dispatched through the responder chain to reach the active EditorViewModel.
@MainActor @objc protocol EditorActions {
    func splitAtPlayhead(_ sender: Any?)
    func trimStartToPlayhead(_ sender: Any?)
    func trimEndToPlayhead(_ sender: Any?)
    func selectForwardOnTrack(_ sender: Any?)
    func selectForwardOnAllTracks(_ sender: Any?)
    func deleteSelectedClips(_ sender: Any?)
    func rippleDeleteSelected(_ sender: Any?)
    func importMedia(_ sender: Any?)
    func newMediaFolder(_ sender: Any?)
    func showExport(_ sender: Any?)
    func toggleMediaPanel(_ sender: Any?)
    func toggleInspectorPanel(_ sender: Any?)
    func toggleAgentPanel(_ sender: Any?)
    func toggleMaximizePanel(_ sender: Any?)
    func setLayoutDefault(_ sender: Any?)
    func setLayoutMedia(_ sender: Any?)
    func setLayoutVertical(_ sender: Any?)
}
