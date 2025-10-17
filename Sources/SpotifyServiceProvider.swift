import Foundation

// MARK: - Spotify Service Provider
class SpotifyServiceProvider: MusicServiceProvider {
    let serviceName = "Spotify"
    
    private var accessToken: String?
    private var tokenExpirationDate: Date?
    
    private let baseURL = "https://api.spotify.com/v1"
    private let tokenURL = "https://accounts.spotify.com/api/token"
    
    var isConfigured: Bool {
        let settingsManager = SettingsManager.shared
        return settingsManager.hasAPIKey(for: .spotifyClientId) &&
               settingsManager.hasAPIKey(for: .spotifyClientSecret)
    }
    
    private var clientId: String? {
        return SettingsManager.shared.retrieveAPIKey(for: .spotifyClientId)
    }
    
    private var clientSecret: String? {
        return SettingsManager.shared.retrieveAPIKey(for: .spotifyClientSecret)
    }
    
    // MARK: - Authentication
    private func getAccessToken() async throws -> String {
        // Check if we have a valid token
        if let token = accessToken,
           let expirationDate = tokenExpirationDate,
           Date() < expirationDate {
            return token
        }
        
        // Get credentials from settings
        guard let clientId = clientId,
              let clientSecret = clientSecret else {
            throw MusicServiceError.notConfigured
        }
        
        // Request new token using Client Credentials flow
        guard let url = URL(string: tokenURL) else {
            throw MusicServiceError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Create authorization header
        let credentials = "\(clientId):\(clientSecret)"
        guard let credentialsData = credentials.data(using: .utf8) else {
            throw MusicServiceError.notConfigured
        }
        let base64Credentials = credentialsData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        
        // Set request body
        let bodyString = "grant_type=client_credentials"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MusicServiceError.searchFailed
        }
        
        let tokenResponse = try JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
        
        // Store token and expiration
        self.accessToken = tokenResponse.access_token
        self.tokenExpirationDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in - 60)) // Subtract 60 seconds for buffer
        
        return tokenResponse.access_token
    }
    
    // MARK: - Search Implementation
    func searchTrack(title: String, artist: String, album: String) async throws -> MusicServiceResult? {
        guard isConfigured else {
            throw MusicServiceError.notConfigured
        }
        
        let token = try await getAccessToken()
        
        // Create search query
        let query = "\(title) artist:\(artist) album:\(album)"
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search?q=\(encodedQuery)&type=track&limit=1") else {
            throw MusicServiceError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MusicServiceError.searchFailed
        }
        
        let searchResponse = try JSONDecoder().decode(SpotifySearchResponse.self, from: data)
        
        guard let spotifyTrack = searchResponse.tracks.items.first else {
            return nil // No match found
        }
        
        return createMusicServiceResult(from: spotifyTrack)
    }
    
    func searchTrackSimple(title: String, artist: String) async throws -> MusicServiceResult? {
        guard isConfigured else {
            throw MusicServiceError.notConfigured
        }
        
        let token = try await getAccessToken()
        
        // Create simpler search query
        let query = "\(title) \(artist)"
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search?q=\(encodedQuery)&type=track&limit=5") else {
            throw MusicServiceError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MusicServiceError.searchFailed
        }
        
        let searchResponse = try JSONDecoder().decode(SpotifySearchResponse.self, from: data)
        
        // Find best match by comparing artist names
        let bestMatch = searchResponse.tracks.items.first { track in
            let trackArtist = track.artists.first?.name.lowercased() ?? ""
            let searchArtist = artist.lowercased()
            return trackArtist.contains(searchArtist) || searchArtist.contains(trackArtist)
        }
        
        guard let spotifyTrack = bestMatch ?? searchResponse.tracks.items.first else {
            return nil // No match found
        }
        
        return createMusicServiceResult(from: spotifyTrack)
    }
    
    private func createMusicServiceResult(from spotifyTrack: SpotifyTrack) -> MusicServiceResult {
        return MusicServiceResult(
            serviceProvider: serviceName,
            trackId: spotifyTrack.id,
            title: spotifyTrack.name,
            artist: spotifyTrack.artists.first?.name ?? "",
            album: spotifyTrack.album.name,
            shareURL: spotifyTrack.external_urls.spotify,
            webPlayerURL: spotifyTrack.external_urls.spotify,
            appURL: "spotify:track:\(spotifyTrack.id)"
        )
    }
}

// MARK: - Spotify API Models (Reused from existing implementation)
struct SpotifySearchResponse: Codable {
    let tracks: SpotifyTracks
}

struct SpotifyTracks: Codable {
    let items: [SpotifyTrack]
}

struct SpotifyTrack: Codable {
    let id: String
    let name: String
    let artists: [SpotifyArtist]
    let album: SpotifyAlbum
    let external_urls: SpotifyExternalURLs
}

struct SpotifyArtist: Codable {
    let name: String
}

struct SpotifyAlbum: Codable {
    let name: String
}

struct SpotifyExternalURLs: Codable {
    let spotify: String
}

struct SpotifyTokenResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}