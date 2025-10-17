import SwiftUI
import AppKit
import Combine

class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var appleMusicMonitor: SimplifiedAppleMusicMonitor
    private var spotifyAPI: SpotifyAPI
    
    @Published var currentSpotifyTrack: TrackInfo?
    @Published var isSearching: Bool = false
    @Published var lastError: String?
    
    init() {
        self.appleMusicMonitor = SimplifiedAppleMusicMonitor()
        self.spotifyAPI = SpotifyAPI()
        
        setupStatusItem()
        setupObservers()
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
        
        updateMenu()
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
            .sink { [weak self] track in
                self?.handleTrackChange(track)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func handleTrackChange(_ track: TrackInfo?) {
        guard let track = track else {
            currentSpotifyTrack = nil
            updateMenu()
            return
        }
        
        // Search for Spotify match
        Task {
            await searchSpotifyMatch(for: track)
        }
    }
    
    private func searchSpotifyMatch(for track: TrackInfo) async {
        DispatchQueue.main.async {
            self.isSearching = true
            self.lastError = nil
        }
        
        do {
            // Try exact search first
            var spotifyTrack = try await spotifyAPI.searchTrack(
                title: track.title,
                artist: track.artist,
                album: track.album
            )
            
            // If no exact match, try simpler search
            if spotifyTrack == nil {
                spotifyTrack = try await spotifyAPI.searchTrackSimple(
                    title: track.title,
                    artist: track.artist
                )
            }
            
            DispatchQueue.main.async {
                self.currentSpotifyTrack = spotifyTrack
                self.isSearching = false
                self.updateMenu()
            }
            
        } catch {
            DispatchQueue.main.async {
                self.lastError = error.localizedDescription
                self.isSearching = false
                self.currentSpotifyTrack = nil
                self.updateMenu()
            }
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
                
                // Spotify section
                if isSearching {
                    let searchingItem = NSMenuItem(title: "🔍 Searching Spotify...", action: nil, keyEquivalent: "")
                    searchingItem.isEnabled = false
                    menu.addItem(searchingItem)
                } else if let spotifyTrack = currentSpotifyTrack {
                    let spotifyItem = NSMenuItem(title: "🎵 Found on Spotify", action: nil, keyEquivalent: "")
                    spotifyItem.isEnabled = false
                    menu.addItem(spotifyItem)
                    
                    // Open in Spotify
                    let openItem = NSMenuItem(title: "Open in Spotify", action: #selector(openInSpotify), keyEquivalent: "")
                    openItem.target = self
                    menu.addItem(openItem)
                    
                    // Copy share link
                    let copyItem = NSMenuItem(title: "Copy Share Link", action: #selector(copySpotifyLink), keyEquivalent: "")
                    copyItem.target = self
                    menu.addItem(copyItem)
                } else if let error = lastError {
                    let errorItem = NSMenuItem(title: "⚠️ \(error)", action: nil, keyEquivalent: "")
                    errorItem.isEnabled = false
                    menu.addItem(errorItem)
                } else {
                    let notFoundItem = NSMenuItem(title: "❌ Not found on Spotify", action: nil, keyEquivalent: "")
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
        
        // Quit option
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func openInSpotify() {
        guard let spotifyURL = currentSpotifyTrack?.spotifyURL,
              let url = URL(string: spotifyURL) else { return }
        
        NSWorkspace.shared.open(url)
    }
    
    @objc private func copySpotifyLink() {
        guard let spotifyURL = currentSpotifyTrack?.spotifyURL else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(spotifyURL, forType: .string)
        
        // Show temporary feedback
        showNotification(title: "Copied!", message: "Spotify link copied to clipboard")
    }
    
    @objc private func refresh() {
        if let currentTrack = appleMusicMonitor.currentTrack {
            Task {
                await searchSpotifyMatch(for: currentTrack)
            }
        }
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
        statusItem = nil
    }
}

// MARK: - Combine Import (already imported above)