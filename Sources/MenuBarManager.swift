import SwiftUI
import AppKit
import Combine

class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var appleMusicMonitor: SimplifiedAppleMusicMonitor
    private var musicServiceManager: MusicServiceManager
    private var settingsWindowController: SettingsWindowController?
    private var urlInputWindowController: URLInputWindowController?
    private var menuDelegate: MenuDelegate?
    
    @Published var isSearching: Bool = false
    @Published var lastError: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    private var isMenuOpen: Bool = false
    
    init() {
        self.appleMusicMonitor = SimplifiedAppleMusicMonitor()
        self.musicServiceManager = MusicServiceManager()
        
        setupStatusItem()
        setupObservers()
        setupPeriodicRefresh()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Try to use custom icon first, fallback to SF Symbol
            if let customIcon = NSImage(named: "MenuBarIcon") {
                button.image = customIcon
                button.image?.size = NSSize(width: 16, height: 16)
                button.image?.isTemplate = true
            } else {
                button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Music Stream Matcher")
                button.image?.size = NSSize(width: 18, height: 18)
                button.image?.isTemplate = true
            }
        }
        
        // Set up menu delegate to track when menu opens/closes
        setupMenuDelegate()
        updateMenu()
    }
    
    private func setupMenuDelegate() {
        // Create a custom menu that tracks open/close state
        let menu = NSMenu()
        menuDelegate = MenuDelegate(manager: self)
        menu.delegate = menuDelegate
        statusItem?.menu = menu
    }
    
    func setCustomIcon(_ iconName: String) {
        guard let button = statusItem?.button else { return }
        
        if let customIcon = NSImage(named: iconName) {
            button.image = customIcon
            button.image?.size = NSSize(width: 16, height: 16)
            button.image?.isTemplate = true
        }
    }
    
    func resetToDefaultIcon() {
        guard let button = statusItem?.button else { return }
        
        if let customIcon = NSImage(named: "MenuBarIcon") {
            button.image = customIcon
            button.image?.size = NSSize(width: 16, height: 16)
            button.image?.isTemplate = true
        } else {
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Music Stream Matcher")
            button.image?.size = NSSize(width: 18, height: 18)
            button.image?.isTemplate = true
        }
    }
    
    private func setupObservers() {
        // Observe changes in Apple Music track
        appleMusicMonitor.$currentTrack
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] track in
                self?.handleTrackChange(track)
            }
            .store(in: &cancellables)
        
        // Observe changes in Apple Music playing state
        appleMusicMonitor.$isPlaying
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)
        
        // Observe changes in music service search results
        musicServiceManager.$searchResults
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)
        
        // Observe search status changes
        musicServiceManager.$isSearching
            .sink { [weak self] isSearching in
                self?.isSearching = isSearching
                self?.updateMenu()
            }
            .store(in: &cancellables)
        
        // Observe changes in provider enabled state
        SettingsManager.shared.$enabledProviders
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)
        
        // Observe API key configuration changes
        SettingsManager.shared.$apiKeysConfigured
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)
    }
    
    private func setupPeriodicRefresh() {
        // Set up a timer for periodic refresh when menu is open
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.isMenuOpen {
                // More frequent updates when menu is open
                self.refreshMenuIfNeeded()
            } else {
                // Less frequent background updates to catch changes
                self.performBackgroundStatusCheck()
            }
        }
    }
    
    private func performBackgroundStatusCheck() {
        // Lightweight background check every few seconds
        // Only update if there are significant changes
        let previousTrack = appleMusicMonitor.currentTrack
        let previousPlayingState = appleMusicMonitor.isPlaying
        
        appleMusicMonitor.checkCurrentTrack()
        
        // Check if there's a meaningful change that warrants a menu update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let currentTrack = self.appleMusicMonitor.currentTrack
            let currentPlayingState = self.appleMusicMonitor.isPlaying
            
            let trackChanged = previousTrack?.title != currentTrack?.title ||
                              previousTrack?.artist != currentTrack?.artist
            let playingStateChanged = previousPlayingState != currentPlayingState
            
            if trackChanged || playingStateChanged {
                self.updateMenu()
            }
        }
    }
    
    private func refreshMenuIfNeeded() {
        // Force a fresh check of the current track and update menu
        appleMusicMonitor.checkCurrentTrack()
        
        // Update menu with latest information
        DispatchQueue.main.async {
            self.updateMenu()
        }
    }
    
    func menuWillOpen() {
        isMenuOpen = true
        // Immediately refresh when menu opens
        refreshMenuIfNeeded()
    }
    
    func menuDidClose() {
        isMenuOpen = false
    }
    
    private func handleTrackChange(_ track: TrackInfo?) {
        guard let track = track else {
            updateMenu()
            return
        }
        
        // Search all music services for matches
        Task {
            await musicServiceManager.searchAllServices(for: track)
        }
    }
    
    private func updateMenu() {
        let menu = NSMenu()
        
        // Current track info
        if let currentTrack = appleMusicMonitor.currentTrack {
            if appleMusicMonitor.isPlaying {
                // Show current Apple Music track
                let trackItem = NSMenuItem(title: "♪ \(currentTrack.displayText)", action: nil, keyEquivalent: "")
                trackItem.isEnabled = false
                menu.addItem(trackItem)
                
                // Show album info
                let albumItem = NSMenuItem(title: "   from \(currentTrack.album)", action: nil, keyEquivalent: "")
                albumItem.isEnabled = false
                menu.addItem(albumItem)
                
                menu.addItem(NSMenuItem.separator())
                
                // Music services section
                if isSearching {
                    let searchingItem = NSMenuItem(title: "🔍 Searching music services...", action: nil, keyEquivalent: "")
                    searchingItem.isEnabled = false
                    menu.addItem(searchingItem)
                } else if musicServiceManager.hasResults() {
                    // Show results for each service
                    let availableServices = musicServiceManager.getAvailableServices()
                    
                    for serviceName in availableServices {
                        if let result = musicServiceManager.getResult(for: serviceName) {
                            // Service header
                            let serviceItem = NSMenuItem(title: "🎵 Found on \(serviceName)", action: nil, keyEquivalent: "")
                            serviceItem.isEnabled = false
                            menu.addItem(serviceItem)
                            
                            // Open in service
                            let openItem = NSMenuItem(title: "   Open in \(serviceName)", action: #selector(openInMusicService(_:)), keyEquivalent: "")
                            openItem.target = self
                            openItem.representedObject = result
                            menu.addItem(openItem)
                            
                            // Copy share link
                            let copyItem = NSMenuItem(title: "   Copy \(serviceName) Link", action: #selector(copyMusicServiceLink(_:)), keyEquivalent: "")
                            copyItem.target = self
                            copyItem.representedObject = result
                            menu.addItem(copyItem)
                            
                            menu.addItem(NSMenuItem.separator())
                        }
                    }
                } else if let error = lastError {
                    let errorItem = NSMenuItem(title: "⚠️ \(error)", action: nil, keyEquivalent: "")
                    errorItem.isEnabled = false
                    menu.addItem(errorItem)
                } else {
                    let notFoundItem = NSMenuItem(title: "❌ No matches found", action: nil, keyEquivalent: "")
                    notFoundItem.isEnabled = false
                    menu.addItem(notFoundItem)
                }
            } else {
                let pausedItem = NSMenuItem(title: "⏸️ Music paused", action: nil, keyEquivalent: "")
                pausedItem.isEnabled = false
                menu.addItem(pausedItem)
            }
        } else {
            let noMusicItem = NSMenuItem(title: "No music currently playing", action: nil, keyEquivalent: "")
            noMusicItem.isEnabled = false
            menu.addItem(noMusicItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Refresh option
        let refreshItem = NSMenuItem(title: "Refresh", action: #selector(refresh), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings option
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        // URL Input option
        let urlInputItem = NSMenuItem(title: "Find Track from URL...", action: #selector(openURLInput), keyEquivalent: "u")
        urlInputItem.target = self
        menu.addItem(urlInputItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit option
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func openInMusicService(_ sender: NSMenuItem) {
        guard let result = sender.representedObject as? MusicServiceResult else { return }
        
        // Try app URL first, then web player URL, then share URL
        let urlToOpen = result.appURL ?? result.webPlayerURL ?? result.shareURL
        
        if let url = URL(string: urlToOpen) {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func copyMusicServiceLink(_ sender: NSMenuItem) {
        guard let result = sender.representedObject as? MusicServiceResult else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(result.shareURL, forType: .string)
        
        // Show temporary feedback
        showNotification(title: "Copied!", message: "\(result.serviceProvider) link copied to clipboard")
    }
    
    @objc private func refresh() {
        if let currentTrack = appleMusicMonitor.currentTrack {
            Task {
                await musicServiceManager.searchAllServices(for: currentTrack)
            }
        }
    }
    
    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func openURLInput() {
        if urlInputWindowController == nil {
            urlInputWindowController = URLInputWindowController()
        }
        
        urlInputWindowController?.showWindow(nil)
        urlInputWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    private func showNotification(title: String, message: String) {
        // Using a simple print for now since NSUserNotification is deprecated
        print("Notification: \(title) - \(message)")
        
        // In a production app, you would use UserNotifications framework:
        // import UserNotifications
        // let content = UNMutableNotificationContent()
        // content.title = title
        // content.body = message
        // let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        // UNUserNotificationCenter.current().add(request)
    }
    
    deinit {
        refreshTimer?.invalidate()
        refreshTimer = nil
        statusItem = nil
        cancellables.removeAll()
    }
}

// MARK: - Menu Delegate
class MenuDelegate: NSObject, NSMenuDelegate {
    weak var manager: MenuBarManager?
    
    init(manager: MenuBarManager) {
        self.manager = manager
        super.init()
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        manager?.menuWillOpen()
    }
    
    func menuDidClose(_ menu: NSMenu) {
        manager?.menuDidClose()
    }
}