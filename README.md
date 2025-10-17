# Music Stream Matcher

A macOS menu bar application that detects currently playing music in Apple Music and finds the equivalent song on Spotify, providing easy access to share links and opening tracks in Spotify.

## Features

- **Real-time Music Detection**: Continuously monitors Apple Music for currently playing tracks
- **Spotify Matching**: Automatically searches Spotify's catalog for matching songs
- **Menu Bar Integration**: Clean, native macOS menu bar interface
- **Interactive Options**:
  - Open matched tracks directly in Spotify
  - Copy Spotify share links to clipboard
  - Real-time status updates
- **Customizable Icon**: Default icon provided with support for custom replacements

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later
- Apple Music app
- Spotify account (for opening tracks)
- Spotify Web API credentials

## Setup Instructions

### 1. Spotify API Setup

1. Go to the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Create a new app
3. Note your **Client ID** and **Client Secret**
4. Open `SpotifyAPI.swift` and replace the placeholder values:
   ```swift
   private let clientId = "YOUR_SPOTIFY_CLIENT_ID"
   private let clientSecret = "YOUR_SPOTIFY_CLIENT_SECRET"
   ```

### 2. Build and Run

1. Open `MusicStreamMatcher.xcodeproj` in Xcode
2. Select your development team in the project settings
3. Build and run the project (⌘+R)

### 3. Permissions

The app will request permission to:
- Access Apple Music (for track detection)
- Send Apple Events (for Apple Music integration)

Grant these permissions when prompted.

## Usage

1. **Launch the App**: The app runs as a menu bar application (look for the music note icon)
2. **Play Music**: Start playing music in Apple Music
3. **View Matches**: Click the menu bar icon to see:
   - Currently playing track information
   - Spotify match status
   - Interactive options when a match is found
4. **Actions**:
   - **Open in Spotify**: Launches the matched track in Spotify
   - **Copy Share Link**: Copies the Spotify URL to your clipboard
   - **Refresh**: Manually refresh the Spotify search

## Menu States

- **No Music Playing**: Shows "No music currently playing"
- **Music Paused**: Shows "Music paused" with track info
- **Searching**: Shows "Searching Spotify..." while finding matches
- **Match Found**: Shows Spotify track with action buttons
- **No Match**: Shows "Not found on Spotify"
- **Error**: Displays error message if API calls fail

## Customization

### Custom Menu Bar Icon

1. Add your custom icon to the Assets catalog
2. Use the `setCustomIcon(_:)` method:
   ```swift
   menuBarManager.setCustomIcon("YourCustomIconName")
   ```
3. Reset to default with `resetToDefaultIcon()`

## Architecture

- **MusicStreamMatcherApp**: Main app entry point
- **MenuBarManager**: Handles menu bar UI and coordinates components
- **AppleMusicMonitor**: Monitors Apple Music using ScriptingBridge
- **SpotifyAPI**: Handles Spotify Web API integration
- **TrackInfo**: Data model for track information

## Troubleshooting

### Common Issues

1. **"No music currently playing" when music is playing**:
   - Ensure Apple Music is running and playing
   - Check that the app has Apple Events permission

2. **Spotify search always fails**:
   - Verify your Spotify API credentials
   - Check your internet connection
   - Ensure your Spotify app credentials are valid

3. **App doesn't appear in menu bar**:
   - Check that LSUIElement is set to true in Info.plist
   - Restart the app

### Debug Mode

For development, you can add logging to track API calls and responses in the SpotifyAPI and AppleMusicMonitor classes.

## Privacy

This app:
- Only accesses currently playing track metadata from Apple Music
- Makes API calls to Spotify's public search endpoints
- Does not store or transmit personal data
- Runs entirely locally except for Spotify API calls

## License

This project is provided as-is for educational and personal use.

## Contributing

Feel free to submit issues and enhancement requests!