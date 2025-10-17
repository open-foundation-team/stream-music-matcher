# Music Stream Matcher - Enhanced Edition

A macOS menu bar application that detects currently playing music in Apple Music and finds equivalent songs across **multiple streaming platforms**, providing easy access to share links and opening tracks in your preferred service.

## 🆕 Enhanced Features

- **Multi-Platform Support**: Find tracks on both Spotify and YouTube Music simultaneously
- **Modular Architecture**: Easy addition of new music streaming services
- **Concurrent Search**: All services search in parallel for faster results
- **Smart Matching**: Intelligent algorithms to find the best matches
- **Service-Specific Actions**: Dedicated buttons for each platform

## 🎯 Core Features

- **Real-time Music Detection**: Continuously monitors Apple Music for currently playing tracks
- **Multi-Service Matching**: Automatically searches multiple streaming catalogs
- **Menu Bar Integration**: Clean, native macOS menu bar interface
- **Interactive Options**:
  - Open matched tracks in Spotify or YouTube Music
  - Copy service-specific share links to clipboard
  - Real-time status updates across all services
- **Customizable Icon**: Default icon provided with support for custom replacements

## 🏗️ Architecture

### Modular Design
- **Protocol-Based Providers**: Each music service implements `MusicServiceProvider`
- **Concurrent Operations**: All services search simultaneously for optimal performance
- **Clean Separation**: Independent service implementations for maintainability
- **Scalable Framework**: Easy addition of new streaming platforms

### Core Components
- **<mcfile name="main.swift" path="/Users/christian.smith/github/weekend-projects/music-stream-matcher/Sources/main.swift"></mcfile>**: App entry point and delegate
- **<mcfile name="MenuBarManager.swift" path="/Users/christian.smith/github/weekend-projects/music-stream-matcher/Sources/MenuBarManager.swift"></mcfile>**: Menu bar UI and service coordination
- **<mcfile name="MusicServiceProvider.swift" path="/Users/christian.smith/github/weekend-projects/music-stream-matcher/Sources/MusicServiceProvider.swift"></mcfile>**: Protocol and manager for music services
- **<mcfile name="SimplifiedAppleMusicMonitor.swift" path="/Users/christian.smith/github/weekend-projects/music-stream-matcher/Sources/SimplifiedAppleMusicMonitor.swift"></mcfile>**: Apple Music integration via AppleScript
- **<mcfile name="SpotifyServiceProvider.swift" path="/Users/christian.smith/github/weekend-projects/music-stream-matcher/Sources/SpotifyServiceProvider.swift"></mcfile>**: Spotify Web API integration
- **<mcfile name="YouTubeMusicServiceProvider.swift" path="/Users/christian.smith/github/weekend-projects/music-stream-matcher/Sources/YouTubeMusicServiceProvider.swift"></mcfile>**: YouTube Music integration via YouTube Data API
- **<mcfile name="TrackInfo.swift" path="/Users/christian.smith/github/weekend-projects/music-stream-matcher/Sources/TrackInfo.swift"></mcfile>**: Data model for track information

## 🚀 Quick Setup

### 1. API Configuration

#### Spotify (Required)
1. Get credentials from [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Update `Sources/SpotifyServiceProvider.swift` with your Client ID and Secret

#### YouTube Music (Optional)
1. Get API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Enable YouTube Data API v3
3. Update `Sources/YouTubeMusicServiceProvider.swift` with your API key

### 2. Build and Run
```bash
swift build
./.build/debug/MusicStreamMatcher
```

## 📱 Enhanced User Experience

### Multi-Service Menu
```
♪ Current Track - Artist
   from Album Name
─────────────────────────
🎵 Found on Spotify
   Open in Spotify
   Copy Spotify Link
─────────────────────────
🎵 Found on YouTube Music
   Open in YouTube Music
   Copy YouTube Link
─────────────────────────
Refresh
Quit
```

### Smart Features
- **Concurrent Search**: All services search simultaneously
- **Graceful Degradation**: Failed services don't block successful ones
- **Intelligent Matching**: Filters out covers, remixes, and low-quality matches
- **Service Fallbacks**: Multiple URL types per service (app, web, share)

## 🔧 Adding New Services

The modular architecture makes adding new streaming services straightforward:

```swift
class NewServiceProvider: MusicServiceProvider {
    let serviceName = "New Service"
    var isConfigured: Bool { /* check credentials */ }
    
    func searchTrack(title: String, artist: String, album: String) async throws -> MusicServiceResult? {
        // Implement service-specific search logic
    }
}
```

Then add to `MusicServiceManager.setupProviders()`.

## 🎵 Supported Services

| Service | Status | Features |
|---------|--------|----------|
| **Spotify** | ✅ Full Support | Web API, Native App Links, Share URLs |
| **YouTube Music** | ✅ Full Support | YouTube Data API, Web Player, Share URLs |
| **Apple Music** | 🔄 Future | Awaiting official API |
| **Tidal** | 📋 Planned | Community requested |

## 🛠️ Requirements

- macOS 13.0 or later
- Swift 5.9 or later
- Apple Music app (for track detection)
- Internet connection (for service APIs)

## 🔒 Privacy & Security

- Only accesses currently playing track metadata from Apple Music
- API calls limited to public search endpoints
- No personal data stored or transmitted
- Runs entirely locally except for service API calls
- Credentials stored in source code (update for production use)

## 📈 Performance

- **Concurrent Search**: Multiple services searched simultaneously
- **Efficient Polling**: Apple Music checked every 2 seconds
- **Smart Caching**: API tokens cached and reused
- **Minimal Resources**: Lightweight background operation

## 🤝 Contributing

The modular architecture welcomes contributions:
- Add new streaming service providers
- Improve search algorithms
- Enhance UI/UX
- Add configuration options

## 📄 License

This project is provided as-is for educational and personal use.

---

**🎵 Discover music across all your favorite platforms with one click! 🎵**