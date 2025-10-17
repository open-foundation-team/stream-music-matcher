import Foundation

// MARK: - YouTube Music Service Provider
class YouTubeMusicServiceProvider: MusicServiceProvider {
    let serviceName = "YouTube Music"
    
    private let baseURL = "https://www.googleapis.com/youtube/v3"
    
    var isConfigured: Bool {
        return SettingsManager.shared.hasAPIKey(for: .youtubeAPIKey)
    }
    
    private var apiKey: String? {
        return SettingsManager.shared.retrieveAPIKey(for: .youtubeAPIKey)
    }
    
    func searchTrack(title: String, artist: String, album: String) async throws -> MusicServiceResult? {
        guard isConfigured else {
            throw MusicServiceError.notConfigured
        }
        
        // Create search query for YouTube Music
        let query = "\(title) \(artist) \(album) music"
        return try await performSearch(query: query, title: title, artist: artist, album: album)
    }
    
    func searchTrackSimple(title: String, artist: String) async throws -> MusicServiceResult? {
        guard isConfigured else {
            throw MusicServiceError.notConfigured
        }
        
        // Create simpler search query
        let query = "\(title) \(artist) music"
        return try await performSearch(query: query, title: title, artist: artist, album: "")
    }
    
    private func performSearch(query: String, title: String, artist: String, album: String) async throws -> MusicServiceResult? {
        guard let apiKey = apiKey else {
            throw MusicServiceError.notConfigured
        }
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search?part=snippet&type=video&q=\(encodedQuery)&maxResults=5&key=\(apiKey)") else {
            throw MusicServiceError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MusicServiceError.searchFailed
        }
        
        let searchResponse = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
        
        // Find the best match
        guard let bestMatch = findBestMatch(from: searchResponse.items, title: title, artist: artist) else {
            return nil
        }
        
        return MusicServiceResult(
            serviceProvider: serviceName,
            trackId: bestMatch.id.videoId,
            title: extractTitle(from: bestMatch.snippet.title, originalTitle: title),
            artist: extractArtist(from: bestMatch.snippet.title, originalArtist: artist),
            album: album,
            shareURL: "https://youtu.be/\(bestMatch.id.videoId)",
            webPlayerURL: "https://music.youtube.com/watch?v=\(bestMatch.id.videoId)",
            appURL: "https://music.youtube.com/watch?v=\(bestMatch.id.videoId)"
        )
    }
    
    private func findBestMatch(from items: [YouTubeSearchItem], title: String, artist: String) -> YouTubeSearchItem? {
        let titleLower = title.lowercased()
        let artistLower = artist.lowercased()
        
        // Score each result based on title and artist match
        let scoredItems = items.map { item -> (item: YouTubeSearchItem, score: Int) in
            let videoTitle = item.snippet.title.lowercased()
            var score = 0
            
            // Check for title match
            if videoTitle.contains(titleLower) {
                score += 10
            }
            
            // Check for artist match
            if videoTitle.contains(artistLower) {
                score += 10
            }
            
            // Prefer official videos and music channels
            let channelTitle = item.snippet.channelTitle.lowercased()
            if channelTitle.contains("official") || channelTitle.contains("music") || channelTitle.contains("records") {
                score += 5
            }
            
            // Prefer videos with "official" in title
            if videoTitle.contains("official") {
                score += 3
            }
            
            // Penalize covers, remixes, etc.
            if videoTitle.contains("cover") || videoTitle.contains("remix") || videoTitle.contains("karaoke") {
                score -= 5
            }
            
            return (item, score)
        }
        
        // Return the highest scoring item
        return scoredItems.max(by: { $0.score < $1.score })?.item
    }
    
    private func extractTitle(from videoTitle: String, originalTitle: String) -> String {
        // Try to extract clean title from YouTube video title
        let cleanTitle = videoTitle
            .replacingOccurrences(of: " (Official Video)", with: "")
            .replacingOccurrences(of: " (Official Audio)", with: "")
            .replacingOccurrences(of: " (Official Music Video)", with: "")
            .replacingOccurrences(of: " [Official Video]", with: "")
            .replacingOccurrences(of: " [Official Audio]", with: "")
        
        // If we can find the original title in the video title, prefer the original
        if videoTitle.lowercased().contains(originalTitle.lowercased()) {
            return originalTitle
        }
        
        return cleanTitle
    }
    
    private func extractArtist(from videoTitle: String, originalArtist: String) -> String {
        // If we can find the original artist in the video title, prefer the original
        if videoTitle.lowercased().contains(originalArtist.lowercased()) {
            return originalArtist
        }
        
        // Try to extract artist from "Artist - Title" format
        if let dashRange = videoTitle.range(of: " - ") {
            let potentialArtist = String(videoTitle[..<dashRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            if !potentialArtist.isEmpty {
                return potentialArtist
            }
        }
        
        return originalArtist
    }
}

// MARK: - YouTube API Models
struct YouTubeSearchResponse: Codable {
    let items: [YouTubeSearchItem]
}

struct YouTubeSearchItem: Codable {
    let id: YouTubeVideoId
    let snippet: YouTubeVideoSnippet
}

struct YouTubeVideoId: Codable {
    let videoId: String
}

struct YouTubeVideoSnippet: Codable {
    let title: String
    let channelTitle: String
    let description: String?
    let publishedAt: String
    
    enum CodingKeys: String, CodingKey {
        case title
        case channelTitle
        case description
        case publishedAt
    }
}