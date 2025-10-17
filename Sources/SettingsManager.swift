import Foundation
import Combine

// MARK: - Settings Manager
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    // MARK: - Published Properties
    @Published var enabledProviders: Set<String> = []
    @Published var apiKeysConfigured: [String: Bool] = [:]
    
    // MARK: - Private Properties
    private let keychainManager = KeychainManager.shared
    private let userDefaults = UserDefaults.standard
    
    // UserDefaults Keys
    private let enabledProvidersKey = "enabledProviders"
    
    // MARK: - Initialization
    private init() {
        loadSettings()
        updateAPIKeyStatus()
    }
    
    // MARK: - Settings Persistence
    private func loadSettings() {
        // Load enabled providers
        if let providersData = userDefaults.data(forKey: enabledProvidersKey),
           let providers = try? JSONDecoder().decode(Set<String>.self, from: providersData) {
            enabledProviders = providers
        } else {
            // Default to all providers enabled
            enabledProviders = Set(MusicServiceType.allCases.map { $0.rawValue })
        }
    }
    
    private func saveSettings() {
        // Save enabled providers
        if let providersData = try? JSONEncoder().encode(enabledProviders) {
            userDefaults.set(providersData, forKey: enabledProvidersKey)
        }
    }
    
    // MARK: - Provider Management
    func setProviderEnabled(_ provider: String, enabled: Bool) {
        if enabled {
            enabledProviders.insert(provider)
        } else {
            enabledProviders.remove(provider)
        }
        saveSettings()
    }
    
    func isProviderEnabled(_ provider: String) -> Bool {
        return enabledProviders.contains(provider)
    }
    
    func getEnabledProviders() -> [String] {
        return Array(enabledProviders).sorted()
    }
    
    // MARK: - API Key Management
    func storeAPIKey(_ key: String, for serviceKey: KeychainManager.ServiceKey) -> Bool {
        let success = keychainManager.storeAPIKey(key, for: serviceKey.rawValue)
        if success {
            updateAPIKeyStatus()
        }
        return success
    }
    
    func retrieveAPIKey(for serviceKey: KeychainManager.ServiceKey) -> String? {
        return keychainManager.retrieveAPIKey(for: serviceKey.rawValue)
    }
    
    func deleteAPIKey(for serviceKey: KeychainManager.ServiceKey) -> Bool {
        let success = keychainManager.deleteAPIKey(for: serviceKey.rawValue)
        if success {
            updateAPIKeyStatus()
        }
        return success
    }
    
    func hasAPIKey(for serviceKey: KeychainManager.ServiceKey) -> Bool {
        return keychainManager.hasAPIKey(for: serviceKey.rawValue)
    }
    
    private func updateAPIKeyStatus() {
        var status: [String: Bool] = [:]
        for serviceKey in KeychainManager.ServiceKey.allCases {
            status[serviceKey.rawValue] = hasAPIKey(for: serviceKey)
        }
        apiKeysConfigured = status
    }
    
    // MARK: - Service Configuration Status
    func isServiceFullyConfigured(_ serviceType: MusicServiceType) -> Bool {
        let requiredKeys = serviceType.requiredAPIKeys
        return requiredKeys.allSatisfy { hasAPIKey(for: $0) }
    }
    
    func getConfigurationStatus() -> [MusicServiceType: Bool] {
        var status: [MusicServiceType: Bool] = [:]
        for serviceType in MusicServiceType.allCases {
            status[serviceType] = isServiceFullyConfigured(serviceType)
        }
        return status
    }
    
    // MARK: - Validation
    func validateAPIKey(_ key: String, for serviceKey: KeychainManager.ServiceKey) -> ValidationResult {
        // Basic validation
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .invalid("API key cannot be empty")
        }
        
        // Service-specific validation
        switch serviceKey {
        case .spotifyClientId:
            return key.count >= 32 ? .valid : .invalid("Spotify Client ID should be at least 32 characters")
        case .spotifyClientSecret:
            return key.count >= 32 ? .valid : .invalid("Spotify Client Secret should be at least 32 characters")
        case .youtubeAPIKey:
            return key.hasPrefix("AIza") ? .valid : .invalid("YouTube API key should start with 'AIza'")
        }
    }
    
    // MARK: - Reset
    func resetAllSettings() {
        // Clear UserDefaults
        userDefaults.removeObject(forKey: enabledProvidersKey)
        
        // Clear Keychain
        for serviceKey in KeychainManager.ServiceKey.allCases {
            _ = keychainManager.deleteAPIKey(for: serviceKey.rawValue)
        }
        
        // Reload defaults
        loadSettings()
        updateAPIKeyStatus()
    }
}

// MARK: - Music Service Types
enum MusicServiceType: String, CaseIterable {
    case spotify = "Spotify"
    case youtubeMusic = "YouTube Music"
    
    var displayName: String {
        return rawValue
    }
    
    var requiredAPIKeys: [KeychainManager.ServiceKey] {
        switch self {
        case .spotify:
            return [.spotifyClientId, .spotifyClientSecret]
        case .youtubeMusic:
            return [.youtubeAPIKey]
        }
    }
    
    var description: String {
        switch self {
        case .spotify:
            return "Stream and discover music on Spotify"
        case .youtubeMusic:
            return "Find music videos and tracks on YouTube Music"
        }
    }
    
    var iconName: String {
        switch self {
        case .spotify:
            return "music.note"
        case .youtubeMusic:
            return "play.rectangle"
        }
    }
}

// MARK: - Validation Result
enum ValidationResult {
    case valid
    case invalid(String)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let message):
            return message
        }
    }
}