import Foundation
import Security

// MARK: - Keychain Manager
class KeychainManager {
    static let shared = KeychainManager()
    
    private let serviceName = "com.musicstreammatcher.apikeys"
    
    private init() {}
    
    // MARK: - API Key Storage
    func storeAPIKey(_ key: String, for service: String) -> Bool {
        let keyData = key.data(using: .utf8) ?? Data()
        
        // Create query for keychain item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: service,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item if it exists
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func retrieveAPIKey(for service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data,
              let key = String(data: keyData, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    func deleteAPIKey(for service: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    func hasAPIKey(for service: String) -> Bool {
        return retrieveAPIKey(for: service) != nil
    }
    
    // MARK: - Bulk Operations
    func storeMultipleKeys(_ keys: [String: String]) -> Bool {
        var allSuccessful = true
        for (service, key) in keys {
            if !storeAPIKey(key, for: service) {
                allSuccessful = false
            }
        }
        return allSuccessful
    }
    
    func retrieveAllKeys(for services: [String]) -> [String: String] {
        var keys: [String: String] = [:]
        for service in services {
            if let key = retrieveAPIKey(for: service) {
                keys[service] = key
            }
        }
        return keys
    }
    
    func clearAllKeys(for services: [String]) -> Bool {
        var allSuccessful = true
        for service in services {
            if !deleteAPIKey(for: service) {
                allSuccessful = false
            }
        }
        return allSuccessful
    }
}

// MARK: - Service Key Identifiers
extension KeychainManager {
    enum ServiceKey: String, CaseIterable {
        case spotifyClientId = "spotify_client_id"
        case spotifyClientSecret = "spotify_client_secret"
        case youtubeAPIKey = "youtube_api_key"
        
        var displayName: String {
            switch self {
            case .spotifyClientId:
                return "Spotify Client ID"
            case .spotifyClientSecret:
                return "Spotify Client Secret"
            case .youtubeAPIKey:
                return "YouTube API Key"
            }
        }
        
        var helpText: String {
            switch self {
            case .spotifyClientId:
                return "Get this from your Spotify Developer Dashboard"
            case .spotifyClientSecret:
                return "Keep this secret! Get it from your Spotify Developer Dashboard"
            case .youtubeAPIKey:
                return "Get this from Google Cloud Console with YouTube Data API v3 enabled"
            }
        }
        
        var isSecret: Bool {
            switch self {
            case .spotifyClientSecret:
                return true
            default:
                return false
            }
        }
    }
}