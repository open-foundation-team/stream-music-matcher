# Music Stream Matcher - Setup Instructions

## Quick Start

Your macOS menu bar application has been successfully created! Here's how to set it up and run it:

## 1. Spotify API Configuration

**IMPORTANT**: Before running the app, you need to configure your Spotify API credentials.

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Log in with your Spotify account
3. Click "Create App"
4. Fill in the details:
   - App name: "Music Stream Matcher"
   - App description: "Menu bar app to match Apple Music tracks with Spotify"
   - Website: (can be left blank)
   - Redirect URI: (can be left blank for this app)
5. Accept the terms and create the app
6. Copy your **Client ID** and **Client Secret**

7. Open the file `Sources/SpotifyAPI.swift` and replace these lines:
   ```swift
   private let clientId = "YOUR_SPOTIFY_CLIENT_ID"
   private let clientSecret = "YOUR_SPOTIFY_CLIENT_SECRET"
   ```
   
   With your actual credentials:
   ```swift
   private let clientId = "your_actual_client_id_here"
   private let clientSecret = "your_actual_client_secret_here"
   ```

## 2. Build and Run

After configuring the Spotify credentials:

```bash
# Navigate to the project directory
cd /Users/christian.smith/github/weekend-projects/music-stream-matcher

# Build the application
swift build

# Run the application
./.build/debug/MusicStreamMatcher
```

## 3. Permissions

When you first run the app, macOS will ask for permissions:

1. **Apple Events Permission**: Required to communicate with Apple Music
   - Click "OK" when prompted
   - If denied, go to System Preferences > Security & Privacy > Privacy > Automation
   - Enable "MusicStreamMatcher" for "Music"

2. **Apple Music Access**: The app uses AppleScript to read currently playing tracks
   - This should work automatically if Apple Music is installed

## 4. Using the App

1. **Start Apple Music** and play a song
2. **Look for the menu bar icon** (music note symbol) in your menu bar
3. **Click the icon** to see:
   - Currently playing track information
   - Spotify search status
   - Options to open in Spotify or copy share link

## 5. Menu Options

- **♪ [Track Name] - [Artist]**: Shows currently playing track
- **🔍 Searching Spotify...**: Appears while searching for matches
- **🎵 Found on Spotify**: Indicates a successful match
- **Open in Spotify**: Opens the matched track in Spotify app/web
- **Copy Share Link**: Copies Spotify URL to clipboard
- **Refresh**: Manually refresh the Spotify search
- **Quit**: Exit the application

## 6. Troubleshooting

### App doesn't appear in menu bar
- Make sure the app is running (check Activity Monitor)
- The icon should appear as a small music note

### "No music currently playing" when music is playing
- Ensure Apple Music app is running and playing music
- Check that the app has Apple Events permission
- Try clicking "Refresh" in the menu

### Spotify search always fails
- Verify your Spotify API credentials are correct
- Check your internet connection
- Make sure your Spotify Developer app is not in "Development Mode" restrictions

### Permission issues
- Go to System Preferences > Security & Privacy > Privacy
- Check "Automation" and "Apple Events" sections
- Enable permissions for MusicStreamMatcher

## 7. Development Notes

- The app uses AppleScript instead of ScriptingBridge for better compatibility
- Spotify searches use the Web API (no Spotify app required for searching)
- The app runs as a menu bar utility (LSUIElement = true)
- Real-time monitoring checks every 2 seconds for track changes

## 8. Building for Distribution

To create a distributable version:

```bash
# Build in release mode
swift build -c release

# The executable will be at:
./.build/release/MusicStreamMatcher
```

For a proper macOS app bundle, you would need to:
1. Create an Xcode project
2. Configure code signing
3. Add proper app icons
4. Create an installer or distribute via App Store

## Support

If you encounter issues:
1. Check the console output when running from terminal
2. Verify all permissions are granted
3. Ensure Spotify API credentials are valid
4. Make sure Apple Music is installed and running

The app is now ready to use! Enjoy seamlessly finding your Apple Music tracks on Spotify! 🎵