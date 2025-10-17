import Foundation

// MARK: - Spotify API Models
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

// MARK: - Spotify API Manager
class SpotifyAPI: ObservableObject {
    private let clientId = "1d2f87861807445eaeb716f9680ca906" // Replace with actual client ID
    private let clientSecret = "b851ce4823344cadafe89d0792ef4967" // Replace with actual client secret
    private var accessToken: String?
    private var tokenExpirationDate: Date?
    
    private let baseURL = "https://api.spotify.com/v1"
    private let tokenURL = "https://accounts.spotify.com/api/token"
    
    init() {
        // Note: In a production app, you would store credentials securely
        // For this demo, you'll need to replace the placeholder values above
    }
    
    // MARK: - Authentication
    private func getAccessToken() async throws -> String {
        // Check if we have a valid token
        if let token = accessToken,
           let expirationDate = tokenExpirationDate,
           Date() < expirationDate {
            return token
        }
        
        // Request new token using Client Credentials flow
        guard let url = URL(string: tokenURL) else {
            throw SpotifyAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Create authorization header
        let credentials = "\(clientId):\(clientSecret)"
        guard let credentialsData = credentials.data(using: .utf8) else {
            throw SpotifyAPIError.authenticationFailed
        }
        let base64Credentials = credentialsData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        
        // Set request body
        let bodyString = "grant_type=client_credentials"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SpotifyAPIError.authenticationFailed
        }
        
        let tokenResponse = try JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
        
        // Store token and expiration
        self.accessToken = tokenResponse.access_token
        self.tokenExpirationDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in - 60)) // Subtract 60 seconds for buffer
        
        return tokenResponse.access_token
    }
    
    // MARK: - Search
    func searchTrack(title: String, artist: String, album: String) async throws -> TrackInfo? {
        let token = try await getAccessToken()
        
        // Create search query
        let query = "\(title) artist:\(artist) album:\(album)"
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search?q=\(encodedQuery)&type=track&limit=1") else {
            throw SpotifyAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SpotifyAPIError.searchFailed
        }
        
        let searchResponse = try JSONDecoder().decode(SpotifySearchResponse.self, from: data)
        
        guard let spotifyTrack = searchResponse.tracks.items.first else {
            return nil // No match found
        }
        
        // Create TrackInfo with Spotify URL
        return TrackInfo(
            trackId: spotifyTrack.id,
            title: spotifyTrack.name,
            album: spotifyTrack.album.name,
            artist: spotifyTrack.artists.first?.name ?? "",
            spotifyURL: spotifyTrack.external_urls.spotify
        )
    }
    
    // MARK: - Alternative search with just title and artist
    func searchTrackSimple(title: String, artist: String) async throws -> TrackInfo? {
        let token = try await getAccessToken()
        
        // Create simpler search query
        let query = "\(title) \(artist)"
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search?q=\(encodedQuery)&type=track&limit=5") else {
            throw SpotifyAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SpotifyAPIError.searchFailed
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
        
        return TrackInfo(
            trackId: spotifyTrack.id,
            title: spotifyTrack.name,
            album: spotifyTrack.album.name,
            artist: spotifyTrack.artists.first?.name ?? "",
            spotifyURL: spotifyTrack.external_urls.spotify
        )
    }
}

// MARK: - Error Types
enum SpotifyAPIError: Error, LocalizedError {
    case invalidURL
    case authenticationFailed
    case searchFailed
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .authenticationFailed:
            return "Spotify authentication failed"
        case .searchFailed:
            return "Spotify search failed"
        case .noResults:
            return "No results found"
        }
    }
}