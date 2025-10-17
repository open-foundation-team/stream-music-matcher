import Foundation
import Combine

// MARK: - URL Search Manager
class URLSearchManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var searchResults: [String: MusicServiceResult] = [:]
    @Published var isSearching: Bool = false
    @Published var lastError: String?
    @Published var originalTrack: URLParser.ParsedTrack?
    
    // MARK: - Private Properties
    private let musicServiceManager: MusicServiceManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(musicServiceManager: MusicServiceManager) {
        self.musicServiceManager = musicServiceManager
        setupObservers()
    }
    
    convenience init() {
        self.init(musicServiceManager: MusicServiceManager())
    }
    
    // MARK: - Setup Observers
    private func setupObservers() {
        // Observe music service manager results
        musicServiceManager.$searchResults
            .sink { [weak self] results in
                self?.searchResults = results
            }
            .store(in: &cancellables)
        
        musicServiceManager.$isSearching
            .sink { [weak self] isSearching in
                self?.isSearching = isSearching
            }
            .store(in: &cancellables)
    }
    
    // MARK: - URL Search Methods
    func searchFromURL(_ urlString: String) async -> Bool {
        // Clear previous results
        DispatchQueue.main.async {
            self.searchResults.removeAll()
            self.lastError = nil
            self.originalTrack = nil
        }
        
        // Parse the URL
        guard let parsedTrack = URLParser.parseURL(urlString) else {
            DispatchQueue.main.async {
                self.lastError = "Invalid or unsupported music URL"
            }
            return false
        }
        
        DispatchQueue.main.async {
            self.originalTrack = parsedTrack
        }
        
        // Get track metadata from the original platform
        guard let trackInfo = await fetchTrackMetadata(for: parsedTrack) else {
            DispatchQueue.main.async {
                self.lastError = "Could not retrieve track information from URL"
            }
            return false
        }
        
        // Search across all platforms
        await musicServiceManager.searchAllServices(for: trackInfo)
        
        return true
    }
    
    // MARK: - Track Metadata Fetching
    private func fetchTrackMetadata(for parsedTrack: URLParser.ParsedTrack) async -> TrackInfo? {
        switch parsedTrack.platform {
        case .spotify:
            return await fetchSpotifyTrackInfo(trackId: parsedTrack.trackId)
        case .appleMusic:
            return await fetchAppleMusicTrackInfo(trackId: parsedTrack.trackId)
        case .youtubeMusic, .youtube:
            return await fetchYouTubeTrackInfo(videoId: parsedTrack.trackId)
        }
    }
    
    private func fetchSpotifyTrackInfo(trackId: String) async -> TrackInfo? {
        // Use existing Spotify service provider to get track details
        let spotifyProvider = SpotifyServiceProvider()
        
        guard spotifyProvider.isConfigured else {
            DispatchQueue.main.async {
                self.lastError = "Spotify API not configured"
            }
            return nil
        }
        
        do {
            // Make a direct API call to get track details
            return try await spotifyProvider.getTrackDetails(trackId: trackId)
        } catch {
            DispatchQueue.main.async {
                self.lastError = "Failed to fetch Spotify track details: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    private func fetchAppleMusicTrackInfo(trackId: String) async -> TrackInfo? {
        // For Apple Music, we'll need to implement iTunes Search API
        return await fetchFromITunesAPI(trackId: trackId)
    }
    
    private func fetchYouTubeTrackInfo(videoId: String) async -> TrackInfo? {
        // Use existing YouTube service provider to get video details
        let youtubeProvider = YouTubeMusicServiceProvider()
        
        guard youtubeProvider.isConfigured else {
            DispatchQueue.main.async {
                self.lastError = "YouTube API not configured"
            }
            return nil
        }
        
        do {
            return try await youtubeProvider.getVideoDetails(videoId: videoId)
        } catch {
            DispatchQueue.main.async {
                self.lastError = "Failed to fetch YouTube track details: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    private func fetchFromITunesAPI(trackId: String) async -> TrackInfo? {
        // iTunes Search API implementation
        let urlString = "https://itunes.apple.com/lookup?id=\(trackId)"
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(URLITunesResponse.self, from: data)
            
            if let track = response.results.first {
                return TrackInfo(
                    trackId: trackId,
                    title: track.trackName,
                    album: track.collectionName,
                    artist: track.artistName
                )
            }
        } catch {
            DispatchQueue.main.async {
                self.lastError = "Failed to fetch iTunes track details: \(error.localizedDescription)"
            }
        }
        
        return nil
    }
    
    // MARK: - Apple Music URL Generation
    func generateAppleMusicURL(for trackInfo: TrackInfo) -> String? {
        // Generate Apple Music search URL
        let query = "\(trackInfo.artist) \(trackInfo.title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return "https://music.apple.com/search?term=\(query)"
    }
    
    // MARK: - Result Management
    func getResultsWithAppleMusic() -> [String: MusicServiceResult] {
        var results = searchResults
        
        // Add Apple Music result if we have track info
        if let trackInfo = getTrackInfoFromResults(),
           let appleMusicURL = generateAppleMusicURL(for: trackInfo) {
            
            let appleMusicResult = MusicServiceResult(
                serviceProvider: "Apple Music",
                trackId: trackInfo.trackId ?? "unknown",
                title: trackInfo.title,
                artist: trackInfo.artist,
                album: trackInfo.album,
                shareURL: appleMusicURL,
                webPlayerURL: appleMusicURL,
                appURL: "music://search?term=\(trackInfo.artist)+\(trackInfo.title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            )
            
            results["Apple Music"] = appleMusicResult
        }
        
        return results
    }
    
    private func getTrackInfoFromResults() -> TrackInfo? {
        // Get track info from any available result
        if let firstResult = searchResults.values.first {
            return TrackInfo(
                trackId: firstResult.trackId,
                title: firstResult.title,
                album: firstResult.album,
                artist: firstResult.artist
            )
        }
        
        // Fallback to original track if available
        if let original = originalTrack {
            return TrackInfo(
                trackId: original.trackId,
                title: original.title ?? "Unknown",
                album: original.album ?? "Unknown",
                artist: original.artist ?? "Unknown"
            )
        }
        
        return nil
    }
    
    // MARK: - Utility Methods
    func hasResults() -> Bool {
        return !searchResults.isEmpty || originalTrack != nil
    }
    
    func clearResults() {
        searchResults.removeAll()
        originalTrack = nil
        lastError = nil
    }
}

// MARK: - URL iTunes API Response Models
private struct URLITunesResponse: Codable {
    let results: [URLITunesTrack]
}

private struct URLITunesTrack: Codable {
    let trackName: String
    let artistName: String
    let collectionName: String
    let trackId: Int
    
    enum CodingKeys: String, CodingKey {
        case trackName
        case artistName
        case collectionName
        case trackId
    }
}