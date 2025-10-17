import SwiftUI
import AppKit

// MARK: - URL Input Window
struct URLInputWindow: View {
    @StateObject private var urlSearchManager = URLSearchManager()
    @State private var inputURL: String = ""
    @State private var isValidURL: Bool = true
    @State private var showingResults: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
                
                Text("Music Track Finder")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Enter a music URL from any platform to find it on all services")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            
            // URL Input Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Music URL")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        PasteableURLTextField(
                            placeholder: "Paste your Spotify, Apple Music, or YouTube link here...",
                            text: $inputURL
                        )
                        .onChange(of: inputURL) { _ in
                            validateURL()
                        }
                    }
                    
                    if !isValidURL {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            
                            Text("Please enter a valid music URL from Spotify, Apple Music, or YouTube")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                // Supported Platforms
                VStack(alignment: .leading, spacing: 4) {
                    Text("Supported platforms:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        PlatformChip(name: "Spotify", icon: "music.note", color: .green)
                        PlatformChip(name: "Apple Music", icon: "music.note", color: .red)
                        PlatformChip(name: "YouTube", icon: "play.rectangle", color: .red)
                    }
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Clear") {
                    clearInput()
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(inputURL.isEmpty)
                
                Spacer()
                
                Button("Find Track") {
                    searchFromURL()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(inputURL.isEmpty || !isValidURL || urlSearchManager.isSearching)
            }
            
            // Loading State
            if urlSearchManager.isSearching {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    
                    Text("Searching across music platforms...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            }
            
            // Results Section
            if showingResults && !urlSearchManager.isSearching {
                URLResultsView(urlSearchManager: urlSearchManager)
            }
            
            // Error Display
            if let error = urlSearchManager.lastError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                )
            }
            
            Spacer()
        }
        .padding(24)
        .frame(width: 500, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Helper Methods
    private func validateURL() {
        if inputURL.isEmpty {
            isValidURL = true
            return
        }
        
        isValidURL = URLParser.isValidMusicURL(inputURL)
    }
    
    private func clearInput() {
        inputURL = ""
        isValidURL = true
        showingResults = false
        urlSearchManager.clearResults()
    }
    
    private func searchFromURL() {
        Task {
            let success = await urlSearchManager.searchFromURL(inputURL)
            DispatchQueue.main.async {
                showingResults = success || urlSearchManager.hasResults()
            }
        }
    }
}

// MARK: - Platform Chip Component
struct PlatformChip: View {
    let name: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            
            Text(name)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
        .foregroundColor(color)
    }
}

// MARK: - URL Results View
struct URLResultsView: View {
    @ObservedObject var urlSearchManager: URLSearchManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Results Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text("Found on these platforms:")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            // Original Track Info
            if let originalTrack = urlSearchManager.originalTrack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Original Track")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: platformIcon(for: originalTrack.platform))
                            .foregroundColor(.accentColor)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            if let title = originalTrack.title {
                                Text(title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            if let artist = originalTrack.artist {
                                Text("by \(artist)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text(originalTrack.platform.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.accentColor.opacity(0.1))
                            )
                            .foregroundColor(.accentColor)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
            }
            
            // Platform Results
            let results = urlSearchManager.getResultsWithAppleMusic()
            
            if !results.isEmpty {
                LazyVStack(spacing: 8) {
                    ForEach(Array(results.keys.sorted()), id: \.self) { serviceName in
                        if let result = results[serviceName] {
                            PlatformResultRow(result: result)
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("No matches found on other platforms")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
        )
    }
    
    private func platformIcon(for platform: URLParser.MusicPlatform) -> String {
        switch platform {
        case .spotify:
            return "music.note"
        case .appleMusic:
            return "music.note"
        case .youtubeMusic, .youtube:
            return "play.rectangle"
        }
    }
}

// MARK: - Platform Result Row
struct PlatformResultRow: View {
    let result: MusicServiceResult
    
    var body: some View {
        HStack(spacing: 12) {
            // Platform Icon
            Image(systemName: platformIcon(for: result.serviceProvider))
                .foregroundColor(platformColor(for: result.serviceProvider))
                .frame(width: 24, height: 24)
            
            // Track Info
            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("by \(result.artist)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 8) {
                // Open in App Button
                if let appURL = result.appURL {
                    Button(action: {
                        openURL(appURL)
                    }) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.accentColor)
                    .help("Open in \(result.serviceProvider) app")
                }
                
                // Open in Web Button
                Button(action: {
                    openURL(result.shareURL)
                }) {
                    Image(systemName: "globe")
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.accentColor)
                .help("Open in web browser")
                
                // Copy Link Button
                Button(action: {
                    copyToClipboard(result.shareURL)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.secondary)
                .help("Copy link")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
    
    private func platformIcon(for serviceName: String) -> String {
        switch serviceName.lowercased() {
        case "spotify":
            return "music.note"
        case "apple music":
            return "music.note"
        case "youtube music", "youtube":
            return "play.rectangle"
        default:
            return "music.note"
        }
    }
    
    private func platformColor(for serviceName: String) -> Color {
        switch serviceName.lowercased() {
        case "spotify":
            return .green
        case "apple music":
            return .red
        case "youtube music", "youtube":
            return .red
        default:
            return .accentColor
        }
    }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
    }
}

// MARK: - URL Input Window Controller
class URLInputWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Music Track Finder"
        window.center()
        window.setFrameAutosaveName("URLInputWindow")
        window.contentView = NSHostingView(rootView: URLInputWindow())
        
        self.init(window: window)
    }
}

// MARK: - Pasteable URL Text Field
struct PasteableURLTextField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String
    
    func makeNSView(context: Context) -> PasteableURLNSTextField {
        let textField = PasteableURLNSTextField()
        textField.placeholderString = placeholder
        textField.stringValue = text
        textField.delegate = context.coordinator
        textField.parent = context.coordinator
        
        // Style the text field to match RoundedBorderTextFieldStyle
        textField.isBordered = true
        textField.bezelStyle = .roundedBezel
        textField.isEditable = true
        textField.isSelectable = true
        textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        
        return textField
    }
    
    func updateNSView(_ nsView: PasteableURLNSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: PasteableURLTextField
        
        init(_ parent: PasteableURLTextField) {
            self.parent = parent
            super.init()
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }
        
        func updateText(_ newText: String) {
            parent.text = newText
        }
    }
}

// Custom NSTextField that properly handles paste operations for URLs
class PasteableURLNSTextField: NSTextField {
    weak var parent: PasteableURLTextField.Coordinator?
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Only handle keyboard shortcuts if this field is the first responder (focused)
        guard self.window?.firstResponder == self.currentEditor() || self.window?.firstResponder == self else {
            return super.performKeyEquivalent(with: event)
        }
        
        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers {
            case "v":
                pasteText()
                return true
            case "c":
                copyText()
                return true
            case "x":
                cutText()
                return true
            case "a":
                selectAll(nil)
                return true
            default:
                break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
    
    @objc func pasteText() {
        // Only paste if this field is focused
        guard self.window?.firstResponder == self.currentEditor() || self.window?.firstResponder == self else {
            return
        }
        
        let pasteboard = NSPasteboard.general
        if let string = pasteboard.string(forType: .string) {
            self.stringValue = string
            parent?.updateText(self.stringValue)
        }
    }
    
    @objc func copyText() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(self.stringValue, forType: .string)
    }
    
    @objc func cutText() {
        copyText()
        self.stringValue = ""
        parent?.updateText(self.stringValue)
    }
    
    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = NSMenu()
        
        // Add paste menu item
        let pasteItem = NSMenuItem(title: "Paste", action: #selector(pasteText), keyEquivalent: "v")
        pasteItem.keyEquivalentModifierMask = .command
        pasteItem.target = self
        pasteItem.isEnabled = NSPasteboard.general.canReadObject(forClasses: [NSString.self], options: nil)
        menu.addItem(pasteItem)
        
        // Add copy menu item
        let copyItem = NSMenuItem(title: "Copy", action: #selector(copyText), keyEquivalent: "c")
        copyItem.keyEquivalentModifierMask = .command
        copyItem.target = self
        copyItem.isEnabled = !stringValue.isEmpty
        menu.addItem(copyItem)
        
        // Add cut menu item
        let cutItem = NSMenuItem(title: "Cut", action: #selector(cutText), keyEquivalent: "x")
        cutItem.keyEquivalentModifierMask = .command
        cutItem.target = self
        cutItem.isEnabled = !stringValue.isEmpty
        menu.addItem(cutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Add select all menu item
        let selectAllItem = NSMenuItem(title: "Select All", action: #selector(selectAll(_:)), keyEquivalent: "a")
        selectAllItem.keyEquivalentModifierMask = .command
        selectAllItem.target = self
        menu.addItem(selectAllItem)
        
        return menu
    }
}