import SwiftUI
import AppKit

// MARK: - Atomic UI Components

// MARK: - Form Section Component
struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding(.leading, 16)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - API Key Input Component
struct APIKeyInput: View {
    let serviceKey: KeychainManager.ServiceKey
    @State private var keyValue: String = ""
    @State private var isSecure: Bool = true
    @State private var validationMessage: String = ""
    @State private var isValid: Bool = true
    
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(serviceKey.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if settingsManager.hasAPIKey(for: serviceKey) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            
            HStack {
                Group {
                    if serviceKey.isSecret && isSecure {
                        PasteableSecureField(
                            placeholder: "Enter \(serviceKey.displayName)",
                            text: $keyValue
                        )
                    } else {
                        PasteableTextField(
                            placeholder: "Enter \(serviceKey.displayName)",
                            text: $keyValue
                        )
                    }
                }
                .onChange(of: keyValue) { _ in
                    validateInput()
                }
                
                if serviceKey.isSecret {
                    Button(action: { isSecure.toggle() }) {
                        Image(systemName: isSecure ? "eye" : "eye.slash")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            HStack {
                Text(serviceKey.helpText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    if settingsManager.hasAPIKey(for: serviceKey) {
                        Button("Clear") {
                            clearAPIKey()
                        }
                        .buttonStyle(LinkButtonStyle())
                        .foregroundColor(.red)
                    }
                    
                    Button(settingsManager.hasAPIKey(for: serviceKey) ? "Update" : "Save") {
                        saveAPIKey()
                    }
                    .buttonStyle(LinkButtonStyle())
                    .disabled(keyValue.isEmpty || !isValid)
                }
            }
            
            if !validationMessage.isEmpty {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundColor(isValid ? .green : .red)
            }
        }
        .onAppear {
            loadExistingKey()
        }
    }
    
    private func loadExistingKey() {
        if let existingKey = settingsManager.retrieveAPIKey(for: serviceKey) {
            keyValue = existingKey
        }
    }
    
    private func validateInput() {
        let result = settingsManager.validateAPIKey(keyValue, for: serviceKey)
        isValid = result.isValid
        validationMessage = result.errorMessage ?? ""
    }
    
    private func saveAPIKey() {
        guard isValid else { return }
        
        if settingsManager.storeAPIKey(keyValue, for: serviceKey) {
            validationMessage = "Saved successfully"
            isValid = true
        } else {
            validationMessage = "Failed to save API key"
            isValid = false
        }
    }
    
    private func clearAPIKey() {
        if settingsManager.deleteAPIKey(for: serviceKey) {
            keyValue = ""
            validationMessage = "API key cleared"
            isValid = true
        }
    }
}

// MARK: - Custom Pasteable Text Fields
struct PasteableTextField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String
    
    func makeNSView(context: Context) -> PasteableNSTextField {
        let textField = PasteableNSTextField()
        textField.placeholderString = placeholder
        textField.stringValue = text
        textField.delegate = context.coordinator
        textField.isBordered = true
        textField.bezelStyle = .roundedBezel
        textField.focusRingType = .default
        textField.isEditable = true
        textField.isSelectable = true
        textField.parent = context.coordinator
        
        return textField
    }
    
    func updateNSView(_ nsView: PasteableNSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: PasteableTextField
        
        init(_ parent: PasteableTextField) {
            self.parent = parent
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

// Custom NSTextField that properly handles paste operations
class PasteableNSTextField: NSTextField {
    weak var parent: PasteableTextField.Coordinator?
    
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

struct PasteableSecureField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String
    
    func makeNSView(context: Context) -> PasteableNSSecureTextField {
        let secureField = PasteableNSSecureTextField()
        secureField.placeholderString = placeholder
        secureField.stringValue = text
        secureField.delegate = context.coordinator
        secureField.isBordered = true
        secureField.bezelStyle = .roundedBezel
        secureField.focusRingType = .default
        secureField.isEditable = true
        secureField.isSelectable = true
        secureField.parent = context.coordinator
        
        return secureField
    }
    
    func updateNSView(_ nsView: PasteableNSSecureTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: PasteableSecureField
        
        init(_ parent: PasteableSecureField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSSecureTextField {
                parent.text = textField.stringValue
            }
        }
        
        func updateText(_ newText: String) {
            parent.text = newText
        }
    }
}

// Custom NSSecureTextField that properly handles paste operations
class PasteableNSSecureTextField: NSSecureTextField {
    weak var parent: PasteableSecureField.Coordinator?
    
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

// MARK: - Provider Toggle Component
struct ProviderToggle: View {
    let serviceType: MusicServiceType
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        HStack {
            Image(systemName: serviceType.iconName)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(serviceType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(serviceType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Toggle("", isOn: Binding(
                    get: { settingsManager.isProviderEnabled(serviceType.rawValue) },
                    set: { settingsManager.setProviderEnabled(serviceType.rawValue, enabled: $0) }
                ))
                .toggleStyle(SwitchToggleStyle())
                
                if !settingsManager.isServiceFullyConfigured(serviceType) {
                    Text("API keys required")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Status Indicator Component
struct StatusIndicator: View {
    let isConfigured: Bool
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: isConfigured ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isConfigured ? .green : .orange)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(isConfigured ? "Configured" : "Needs Setup")
                .font(.caption)
                .foregroundColor(isConfigured ? .green : .orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isConfigured ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                )
        }
    }
}

// MARK: - Help Text Component
struct HelpText: View {
    let text: String
    let style: HelpTextStyle
    
    enum HelpTextStyle {
        case info
        case warning
        case error
        
        var color: Color {
            switch self {
            case .info: return .secondary
            case .warning: return .orange
            case .error: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle"
            case .warning: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: style.icon)
                .foregroundColor(style.color)
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundColor(style.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(style.color.opacity(0.1))
        )
    }
}

// MARK: - Action Button Component
struct SettingsButton: View {
    let title: String
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .accentColor
            case .secondary: return Color(NSColor.controlBackgroundColor)
            case .destructive: return .red
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return .primary
            case .destructive: return .white
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(style.foregroundColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(style.backgroundColor)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Divider Component
struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(NSColor.separatorColor))
            .frame(height: 1)
            .padding(.vertical, 8)
    }
}

// MARK: - Custom Toggle Style
struct SwitchToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                .frame(width: 44, height: 24)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}