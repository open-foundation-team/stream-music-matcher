import Foundation

struct TrackInfo: Equatable {
    let trackId: String?
    let title: String
    let album: String
    let artist: String
    
    // Legacy Spotify URL for backward compatibility
    let spotifyURL: String?
    
    init(trackId: String? = nil, title: String, album: String, artist: String, spotifyURL: String? = nil) {
        self.trackId = trackId
        self.title = title
        self.album = album
        self.artist = artist
        self.spotifyURL = spotifyURL
    }
    
    var displayText: String {
        return "\(title) - \(artist)"
    }
    
    var fullDisplayText: String {
        return "\(title)\nby \(artist)\nfrom \(album)"
    }
    
    // Helper method to create search query
    var searchQuery: String {
        return "\(title) \(artist)"
    }
    
    // Helper method for detailed search query
    var detailedSearchQuery: String {
        return "\(title) \(artist) \(album)"
    }
}