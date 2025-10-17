import Foundation

struct TrackInfo: Equatable {
    let trackId: String?
    let title: String
    let album: String
    let artist: String
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
}