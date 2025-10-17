import SwiftUI
import AppKit

// Main entry point for the application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarManager: MenuBarManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon since this is a menu bar app
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize menu bar manager
        menuBarManager = MenuBarManager()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        menuBarManager = nil
    }
}