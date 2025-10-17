import Foundation

// MARK: - URL Parser for Music Platforms
class URLParser {
    
    // MARK: - Supported Platform Types
    enum MusicPlatform: String, CaseIterable {
        case spotify = "Spotify"
        case appleMusic = "Apple Music"
        case youtubeMusic = "YouTube Music"
        case youtube = "YouTube"
        
        var domains: [String] {
            switch self {
            case .spotify:
                return ["open.spotify.com", "spotify.com"]
            case .appleMusic:
                return ["music.apple.com", "itunes.apple.com"]
            case .youtubeMusic:
                return ["music.youtube.com"]
            case .youtube:
                return ["youtube.com", "youtu.be", "www.youtube.com"]
            }
        }
    }
    
    // MARK: - Parsed Track Information
    struct ParsedTrack {
        let platform: MusicPlatform
        let trackId: String
        let title: String?
        let artist: String?
        let album: String?
        let originalURL: String
        
        init(platform: MusicPlatform, trackId: String, title: String? = nil, artist: String? = nil, album: String? = nil, originalURL: String) {
            self.platform = platform
            self.trackId = trackId
            self.title = title
            self.artist = artist
            self.album = album
            self.originalURL = originalURL
        }
    }
    
    // MARK: - URL Parsing Methods
    static func parseURL(_ urlString: String) -> ParsedTrack? {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)),
              let host = url.host else {
            return nil
        }
        
        // Determine platform based on domain
        guard let platform = identifyPlatform(from: host) else {
            return nil
        }
        
        // Parse based on platform
        switch platform {
        case .spotify:
            return parseSpotifyURL(url)
        case .appleMusic:
            return parseAppleMusicURL(url)
        case .youtubeMusic:
            return parseYouTubeMusicURL(url)
        case .youtube:
            return parseYouTubeURL(url)
        }
    }
    
    private static func identifyPlatform(from host: String) -> MusicPlatform? {
        for platform in MusicPlatform.allCases {
            if platform.domains.contains(where: { host.contains($0) }) {
                return platform
            }
        }
        return nil
    }
    
    // MARK: - Platform-Specific Parsers
    
    private static func parseSpotifyURL(_ url: URL) -> ParsedTrack? {
        let pathComponents = url.pathComponents
        
        // Handle different Spotify URL formats
        // https://open.spotify.com/track/4iV5W9uYEdYUVa79Axb7Rh
        // https://open.spotify.com/album/1DFixLWuPkv3KT3TnV35m3/track/4iV5W9uYEdYUVa79Axb7Rh
        
        if pathComponents.contains("track"), let trackIndex = pathComponents.firstIndex(of: "track") {
            let trackIdIndex = trackIndex + 1
            if trackIdIndex < pathComponents.count {
                let trackId = pathComponents[trackIdIndex].components(separatedBy: "?").first ?? pathComponents[trackIdIndex]
                return ParsedTrack(platform: .spotify, trackId: trackId, originalURL: url.absoluteString)
            }
        }
        
        return nil
    }
    
    private static func parseAppleMusicURL(_ url: URL) -> ParsedTrack? {
        let pathComponents = url.pathComponents
        
        // Handle Apple Music URL formats
        // https://music.apple.com/us/album/song-name/1234567890?i=0987654321
        // https://music.apple.com/us/song/song-name/1234567890
        
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let trackId = queryItems.first(where: { $0.name == "i" })?.value {
            return ParsedTrack(platform: .appleMusic, trackId: trackId, originalURL: url.absoluteString)
        }
        
        // Handle song URLs
        if pathComponents.contains("song"), let songIndex = pathComponents.firstIndex(of: "song") {
            let trackIdIndex = songIndex + 2 // Skip song name
            if trackIdIndex < pathComponents.count {
                let trackId = pathComponents[trackIdIndex].components(separatedBy: "?").first ?? pathComponents[trackIdIndex]
                return ParsedTrack(platform: .appleMusic, trackId: trackId, originalURL: url.absoluteString)
            }
        }
        
        return nil
    }
    
    private static func parseYouTubeMusicURL(_ url: URL) -> ParsedTrack? {
        // Handle YouTube Music URL formats
        // https://music.youtube.com/watch?v=dQw4w9WgXcQ
        
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let videoId = queryItems.first(where: { $0.name == "v" })?.value {
            return ParsedTrack(platform: .youtubeMusic, trackId: videoId, originalURL: url.absoluteString)
        }
        
        return nil
    }
    
    private static func parseYouTubeURL(_ url: URL) -> ParsedTrack? {
        // Handle YouTube URL formats
        // https://www.youtube.com/watch?v=dQw4w9WgXcQ
        // https://youtu.be/dQw4w9WgXcQ
        
        if url.host?.contains("youtu.be") == true {
            // Short URL format
            let videoId = String(url.pathComponents.last?.components(separatedBy: "?").first ?? "")
            if !videoId.isEmpty {
                return ParsedTrack(platform: .youtube, trackId: videoId, originalURL: url.absoluteString)
            }
        } else if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
                  let videoId = queryItems.first(where: { $0.name == "v" })?.value {
            return ParsedTrack(platform: .youtube, trackId: videoId, originalURL: url.absoluteString)
        }
        
        return nil
    }
    
    // MARK: - URL Validation
    static func isValidMusicURL(_ urlString: String) -> Bool {
        return parseURL(urlString) != nil
    }
    
    // MARK: - Platform Detection
    static func detectPlatform(_ urlString: String) -> MusicPlatform? {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)),
              let host = url.host else {
            return nil
        }
        
        return identifyPlatform(from: host)
    }
}