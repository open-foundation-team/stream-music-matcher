import Foundation
import AppKit

// MARK: - Simplified Apple Music Monitor using AppleScript
class SimplifiedAppleMusicMonitor: ObservableObject {
    @Published var currentTrack: TrackInfo?
    @Published var isPlaying: Bool = false
    
    private var timer: Timer?
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.performTrackCheck()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    // Public method to allow external refresh requests
    func checkCurrentTrack() {
        performTrackCheck()
    }
    
    private func performTrackCheck() {
        // Check if Music app is running
        let runningApps = NSWorkspace.shared.runningApplications
        let musicApp = runningApps.first { $0.bundleIdentifier == "com.apple.Music" }
        
        guard musicApp != nil else {
            DispatchQueue.main.async {
                self.currentTrack = nil
                self.isPlaying = false
            }
            return
        }
        
        // Use AppleScript to get current track info
        let script = """
        tell application "Music"
            if player state is playing then
                set trackName to name of current track
                set trackArtist to artist of current track
                set trackAlbum to album of current track
                set trackID to database ID of current track
                return trackName & "|||" & trackArtist & "|||" & trackAlbum & "|||" & trackID & "|||playing"
            else if player state is paused then
                set trackName to name of current track
                set trackArtist to artist of current track
                set trackAlbum to album of current track
                set trackID to database ID of current track
                return trackName & "|||" & trackArtist & "|||" & trackAlbum & "|||" & trackID & "|||paused"
            else
                return "|||||||stopped"
            end if
        end tell
        """
        
        executeAppleScript(script) { [weak self] result in
            self?.processScriptResult(result)
        }
    }
    
    private func executeAppleScript(_ script: String, completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            var error: NSDictionary?
            let appleScript = NSAppleScript(source: script)
            let result = appleScript?.executeAndReturnError(&error)
            
            if let error = error {
                print("AppleScript error: \(error)")
                completion(nil)
            } else {
                completion(result?.stringValue)
            }
        }
    }
    
    private func processScriptResult(_ result: String?) {
        guard let result = result else {
            DispatchQueue.main.async {
                self.currentTrack = nil
                self.isPlaying = false
            }
            return
        }
        
        let components = result.components(separatedBy: "|||")
        guard components.count >= 5 else {
            DispatchQueue.main.async {
                self.currentTrack = nil
                self.isPlaying = false
            }
            return
        }
        
        let trackName = components[0].isEmpty ? nil : components[0]
        let trackArtist = components[1].isEmpty ? nil : components[1]
        let trackAlbum = components[2].isEmpty ? nil : components[2]
        let trackID = components[3].isEmpty ? nil : components[3]
        let playerState = components[4]
        
        let playing = playerState == "playing"
        
        guard let name = trackName, let artist = trackArtist, let album = trackAlbum else {
            DispatchQueue.main.async {
                self.currentTrack = nil
                self.isPlaying = playing
            }
            return
        }
        
        let trackInfo = TrackInfo(
            trackId: trackID,
            title: name,
            album: album,
            artist: artist
        )
        
        DispatchQueue.main.async {
            // Only update if track has changed
            if self.currentTrack != trackInfo {
                self.currentTrack = trackInfo
            }
            self.isPlaying = playing
        }
    }
    
    func getCurrentTrack() -> TrackInfo? {
        return currentTrack
    }
}