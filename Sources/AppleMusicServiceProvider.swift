import Foundation

// MARK: - Apple Music Service Provider
class AppleMusicServiceProvider: MusicServiceProvider {
    let serviceName = "Apple Music"
    
    // Apple Music doesn't require API keys for basic URL generation
    var isConfigured: Bool {
        return true
    }
    
    // MARK: - Search Methods
    func searchTrack(title: String, artist: String, album: String) async throws -> MusicServiceResult? {
        // Create Apple Music search URL
        let query = "\(title) \(artist) \(album)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let searchURL = "https://music.apple.com/search?term=\(query)"
        let appURL = "music://search?term=\(query)"
        
        return MusicServiceResult(
            serviceProvider: serviceName,
            trackId: generateTrackId(title: title, artist: artist),
            title: title,
            artist: artist,
            album: album,
            shareURL: searchURL,
            webPlayerURL: searchURL,
            appURL: appURL
        )
    }
    
    func searchTrackSimple(title: String, artist: String) async throws -> MusicServiceResult? {
        return try await searchTrack(title: title, artist: artist, album: "")
    }
    
    // MARK: - URL Generation Methods
    func generateSearchURL(for trackInfo: TrackInfo) -> String {
        let query = "\(trackInfo.artist) \(trackInfo.title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return "https://music.apple.com/search?term=\(query)"
    }
    
    func generateAppURL(for trackInfo: TrackInfo) -> String {
        let query = "\(trackInfo.artist) \(trackInfo.title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return "music://search?term=\(query)"
    }
    
    func generateDeepLink(trackId: String) -> String {
        // Apple Music deep link format
        return "music://music.apple.com/song/\(trackId)"
    }
    
    // MARK: - iTunes Search API Integration
    func searchITunes(for trackInfo: TrackInfo) async throws -> MusicServiceResult? {
        let query = "\(trackInfo.artist) \(trackInfo.title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://itunes.apple.com/search?term=\(query)&media=music&entity=song&limit=1"
        
        guard let url = URL(string: urlString) else {
            throw MusicServiceError.invalidResponse
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MusicServiceError.networkError
        }
        
        let searchResponse = try JSONDecoder().decode(ITunesSearchResponse.self, from: data)
        
        guard let track = searchResponse.results.first else {
            throw MusicServiceError.noResults
        }
        
        // Generate Apple Music URLs
        let appleMusicURL = generateAppleMusicURL(from: track)
        let appURL = generateAppURL(for: trackInfo)
        
        return MusicServiceResult(
            serviceProvider: serviceName,
            trackId: String(track.trackId),
            title: track.trackName,
            artist: track.artistName,
            album: track.collectionName,
            shareURL: appleMusicURL,
            webPlayerURL: appleMusicURL,
            appURL: appURL
        )
    }
    
    private func generateAppleMusicURL(from track: ITunesTrack) -> String {
        // Convert iTunes URL to Apple Music URL
        if let appleMusicURL = track.trackViewUrl?.replacingOccurrences(of: "itunes.apple.com", with: "music.apple.com") {
            return appleMusicURL
        }
        
        // Fallback to search URL
        let query = "\(track.artistName) \(track.trackName)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return "https://music.apple.com/search?term=\(query)"
    }
    
    // MARK: - Helper Methods
    private func generateTrackId(title: String, artist: String) -> String {
        // Generate a simple hash-based ID for Apple Music results
        let combined = "\(artist)-\(title)".lowercased()
        return String(combined.hashValue)
    }
    
    // MARK: - URL Parsing
    func parseAppleMusicURL(_ urlString: String) -> (trackId: String?, searchTerm: String?) {
        guard let url = URL(string: urlString) else {
            return (nil, nil)
        }
        
        let pathComponents = url.pathComponents
        
        // Handle Apple Music URL formats
        if pathComponents.contains("song"), let songIndex = pathComponents.firstIndex(of: "song") {
            let trackIdIndex = songIndex + 2 // Skip song name
            if trackIdIndex < pathComponents.count {
                let trackId = pathComponents[trackIdIndex].components(separatedBy: "?").first ?? pathComponents[trackIdIndex]
                return (trackId, nil)
            }
        }
        
        // Handle search URLs
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let searchTerm = queryItems.first(where: { $0.name == "term" })?.value {
            return (nil, searchTerm)
        }
        
        return (nil, nil)
    }
}

// MARK: - iTunes Search API Models
struct ITunesSearchResponse: Codable {
    let results: [ITunesTrack]
}

struct ITunesTrack: Codable {
    let trackId: Int
    let trackName: String
    let artistName: String
    let collectionName: String
    let trackViewUrl: String?
    let previewUrl: String?
    let artworkUrl100: String?
    
    enum CodingKeys: String, CodingKey {
        case trackId
        case trackName
        case artistName
        case collectionName
        case trackViewUrl
        case previewUrl
        case artworkUrl100
    }
}