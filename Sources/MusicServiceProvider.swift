import Foundation

// MARK: - Music Service Provider Protocol
protocol MusicServiceProvider: ObservableObject {
    var serviceName: String { get }
    var isConfigured: Bool { get }
    
    func searchTrack(title: String, artist: String, album: String) async throws -> MusicServiceResult?
    func searchTrackSimple(title: String, artist: String) async throws -> MusicServiceResult?
}

// MARK: - Music Service Result
struct MusicServiceResult {
    let serviceProvider: String
    let trackId: String
    let title: String
    let artist: String
    let album: String
    let shareURL: String
    let webPlayerURL: String?
    let appURL: String?
    
    init(serviceProvider: String, trackId: String, title: String, artist: String, album: String, shareURL: String, webPlayerURL: String? = nil, appURL: String? = nil) {
        self.serviceProvider = serviceProvider
        self.trackId = trackId
        self.title = title
        self.artist = artist
        self.album = album
        self.shareURL = shareURL
        self.webPlayerURL = webPlayerURL
        self.appURL = appURL
    }
}

// MARK: - Music Service Manager
class MusicServiceManager: ObservableObject {
    @Published var searchResults: [String: MusicServiceResult] = [:]
    @Published var isSearching: Bool = false
    @Published var lastError: String?
    
    private var allProviders: [any MusicServiceProvider] = []
    private let settingsManager = SettingsManager.shared
    
    init() {
        setupProviders()
    }
    
    private func setupProviders() {
        // Initialize all available music service providers
        allProviders.append(SpotifyServiceProvider())
        allProviders.append(YouTubeMusicServiceProvider())
    }
    
    private func getEnabledProviders() -> [any MusicServiceProvider] {
        return allProviders.filter { provider in
            let isConfigured = provider.isConfigured
            let isEnabled = settingsManager.isProviderEnabled(provider.serviceName)
            return isConfigured && isEnabled
        }
    }
    
    func searchAllServices(for track: TrackInfo) async {
        DispatchQueue.main.async {
            self.isSearching = true
            self.lastError = nil
            self.searchResults.removeAll()
        }
        
        // Get only enabled and configured providers
        let enabledProviders = getEnabledProviders()
        
        // Search all enabled providers concurrently
        await withTaskGroup(of: (String, MusicServiceResult?).self) { group in
            for provider in enabledProviders {
                group.addTask {
                    do {
                        // Try exact search first
                        var result = try await provider.searchTrack(
                            title: track.title,
                            artist: track.artist,
                            album: track.album
                        )
                        
                        // If no exact match, try simpler search
                        if result == nil {
                            result = try await provider.searchTrackSimple(
                                title: track.title,
                                artist: track.artist
                            )
                        }
                        
                        return (provider.serviceName, result)
                    } catch {
                        print("Error searching \(provider.serviceName): \(error)")
                        return (provider.serviceName, nil)
                    }
                }
            }
            
            // Collect results
            for await (serviceName, result) in group {
                if let result = result {
                    DispatchQueue.main.async {
                        self.searchResults[serviceName] = result
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            self.isSearching = false
        }
    }
    
    func getResult(for serviceName: String) -> MusicServiceResult? {
        return searchResults[serviceName]
    }
    
    func hasResults() -> Bool {
        return !searchResults.isEmpty
    }
    
    func getAvailableServices() -> [String] {
        return Array(searchResults.keys).sorted()
    }
}

// MARK: - Music Service Errors
enum MusicServiceError: Error, LocalizedError {
    case notConfigured
    case searchFailed
    case noResults
    case invalidResponse
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Service not configured"
        case .searchFailed:
            return "Search failed"
        case .noResults:
            return "No results found"
        case .invalidResponse:
            return "Invalid response from service"
        case .networkError:
            return "Network error"
        }
    }
}