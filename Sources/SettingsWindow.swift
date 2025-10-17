import SwiftUI
import AppKit

// MARK: - Settings Window
struct SettingsWindow: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @State private var selectedTab: SettingsTab = .apiKeys
    
    enum SettingsTab: String, CaseIterable {
        case apiKeys = "API Keys"
        case providers = "Music Services"
        case about = "About"
        
        var icon: String {
            switch self {
            case .apiKeys: return "key"
            case .providers: return "music.note.list"
            case .about: return "info.circle"
            }
        }
    }
    
    var body: some View {
        HSplitView {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Music Stream Matcher")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Settings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                
                // Navigation
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(SettingsTab.allCases, id: \.self) { tab in
                        SettingsTabButton(
                            tab: tab,
                            isSelected: selectedTab == tab,
                            action: { selectedTab = tab }
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                
                Spacer()
                
                // Footer
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    SettingsButton(
                        title: "Reset All Settings",
                        style: .destructive
                    ) {
                        resetAllSettings()
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.bottom, 12)
            }
            .frame(minWidth: 200, maxWidth: 250)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Main Content
            VStack(alignment: .leading, spacing: 0) {
                // Content Header
                HStack {
                    Image(systemName: selectedTab.icon)
                        .foregroundColor(.accentColor)
                        .font(.title2)
                    
                    Text(selectedTab.rawValue)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color(NSColor.windowBackgroundColor))
                
                Divider()
                
                // Tab Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        switch selectedTab {
                        case .apiKeys:
                            APIKeysView()
                        case .providers:
                            ProvidersView()
                        case .about:
                            AboutView()
                        }
                    }
                    .padding(24)
                }
                .background(Color(NSColor.windowBackgroundColor))
            }
            .frame(minWidth: 500)
        }
        .frame(width: 800, height: 600)
    }
    
    private func resetAllSettings() {
        let alert = NSAlert()
        alert.messageText = "Reset All Settings"
        alert.informativeText = "This will clear all API keys and reset preferences. This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            settingsManager.resetAllSettings()
        }
    }
}

// MARK: - Settings Tab Button
struct SettingsTabButton: View {
    let tab: SettingsWindow.SettingsTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 16)
                
                Text(tab.rawValue)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - API Keys View
struct APIKeysView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HelpText(
                text: "Enter your API keys to enable music service integrations. Keys are stored securely in your macOS Keychain.",
                style: .info
            )
            
            SettingsSection("Spotify Configuration") {
                APIKeyInput(serviceKey: .spotifyClientId)
                APIKeyInput(serviceKey: .spotifyClientSecret)
                
                HelpText(
                    text: "Get your Spotify credentials from the Spotify Developer Dashboard. Create a new app and copy the Client ID and Client Secret.",
                    style: .info
                )
            }
            
            SettingsDivider()
            
            SettingsSection("YouTube Music Configuration") {
                APIKeyInput(serviceKey: .youtubeAPIKey)
                
                HelpText(
                    text: "Get your YouTube API key from Google Cloud Console. Enable the YouTube Data API v3 for your project.",
                    style: .info
                )
            }
            
            SettingsDivider()
            
            SettingsSection("Configuration Status") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(MusicServiceType.allCases, id: \.self) { serviceType in
                        StatusIndicator(
                            isConfigured: settingsManager.isServiceFullyConfigured(serviceType),
                            title: serviceType.displayName
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Providers View
struct ProvidersView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HelpText(
                text: "Enable or disable music service providers. Disabled providers won't appear in search results.",
                style: .info
            )
            
            SettingsSection("Available Music Services") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(MusicServiceType.allCases, id: \.self) { serviceType in
                        ProviderToggle(serviceType: serviceType)
                        
                        if serviceType != MusicServiceType.allCases.last {
                            Divider()
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
            
            if !settingsManager.getEnabledProviders().isEmpty {
                SettingsDivider()
                
                SettingsSection("Active Services") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Currently enabled: \(settingsManager.getEnabledProviders().joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        let configuredCount = settingsManager.getConfigurationStatus().values.filter { $0 }.count
                        let totalCount = MusicServiceType.allCases.count
                        
                        Text("\(configuredCount) of \(totalCount) services fully configured")
                            .font(.caption)
                            .foregroundColor(configuredCount == totalCount ? .green : .orange)
                    }
                }
            }
        }
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SettingsSection("About Music Stream Matcher") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Version 2.0.0")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("A macOS menu bar application that detects currently playing music in Apple Music and finds equivalent songs across multiple streaming platforms.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            SettingsDivider()
            
            SettingsSection("Supported Services") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(MusicServiceType.allCases, id: \.self) { serviceType in
                        HStack {
                            Image(systemName: serviceType.iconName)
                                .foregroundColor(.accentColor)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(serviceType.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(serviceType.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
            
            SettingsDivider()
            
            SettingsSection("Privacy & Security") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• API keys are stored securely in your macOS Keychain")
                    Text("• Only currently playing track metadata is accessed from Apple Music")
                    Text("• No personal data is transmitted or stored by the application")
                    Text("• All music service searches use public APIs")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Settings Window Controller
class SettingsWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Settings"
        window.center()
        window.setFrameAutosaveName("SettingsWindow")
        window.contentView = NSHostingView(rootView: SettingsWindow())
        
        self.init(window: window)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.titlebarAppearsTransparent = false
        window?.titleVisibility = .visible
    }
}