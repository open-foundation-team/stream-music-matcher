# Settings Window Guide - Music Stream Matcher

## 🎛️ New Settings Interface

Your Music Stream Matcher now includes a comprehensive settings window that follows Apple's design standards and provides secure API key management with persistent storage.

## 🚀 Accessing Settings

### From Menu Bar

1. Click the Music Stream Matcher icon in your menu bar
2. Select **"Settings..."** (or press ⌘,)
3. The settings window will open with three main sections

### Keyboard Shortcut

-   **⌘,** (Command + Comma) - Standard macOS settings shortcut

## 🔧 Settings Window Overview

### Three Main Sections

#### 1. **API Keys** 🔑

-   Secure storage and management of service credentials
-   Real-time validation and status indicators
-   Keychain integration for maximum security

#### 2. **Music Services** 🎵

-   Toggle individual music providers on/off
-   View configuration status for each service
-   Control which services appear in search results

#### 3. **About** ℹ️

-   Application information and version details
-   Privacy and security information
-   Supported services overview

## 🔐 API Key Management

### Spotify Configuration

1. **Get Credentials**:

    - Visit [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
    - Create a new app
    - Copy your **Client ID** and **Client Secret**

2. **Enter in Settings**:

    - Open Settings → API Keys
    - Enter your Spotify Client ID
    - Enter your Spotify Client Secret (hidden by default)
    - Click **Save** for each field

3. **Security Features**:
    - Client Secret is masked by default (click eye icon to reveal)
    - Real-time validation ensures correct format
    - Keys stored securely in macOS Keychain
    - **Clear** button to remove stored keys

### YouTube Music Configuration

1. **Get API Key**:

    - Visit [Google Cloud Console](https://console.cloud.google.com/)
    - Create or select a project
    - Enable **YouTube Data API v3**
    - Create an API Key

2. **Enter in Settings**:

    - Open Settings → API Keys
    - Enter your YouTube API Key
    - Click **Save**

3. **Validation**:
    - Ensures API key starts with "AIza" (YouTube format)
    - Validates minimum length requirements

## 🎵 Music Services Management

### Provider Controls

-   **Toggle Switches**: Enable/disable individual music services
-   **Status Indicators**: Shows which services are fully configured
-   **Real-time Updates**: Changes apply immediately to search behavior

### Service Status

-   ✅ **Configured**: Service has all required API keys
-   ⚠️ **Needs Setup**: Missing API keys or configuration
-   🔄 **Active**: Currently enabled and searching

### Dynamic Menu Updates

-   Disabled services won't appear in menu bar results
-   Only enabled and configured services will search for tracks
-   Changes persist between app launches

## 💾 Data Persistence

### Secure Storage

-   **API Keys**: Stored in macOS Keychain (encrypted)
-   **Preferences**: Stored in UserDefaults (standard macOS location)
-   **No Cloud Sync**: All data remains on your device

### Between Sessions

-   API keys persist until manually cleared
-   Service enable/disable preferences saved automatically
-   Window position and size remembered

## 🎨 User Interface Features

### Apple Design Standards

-   **Native macOS Controls**: Standard toggles, buttons, and text fields
-   **Proper Typography**: System fonts and sizing
-   **Color Consistency**: Follows system appearance (Light/Dark mode)
-   **Accessibility**: Full VoiceOver and keyboard navigation support

### Visual Hierarchy

-   **Clear Sections**: Organized with proper spacing and dividers
-   **Status Indicators**: Color-coded feedback (green = good, orange = needs attention)
-   **Help Text**: Contextual information and guidance
-   **Validation Feedback**: Real-time input validation with clear messages

### Responsive Design

-   **Resizable Window**: Minimum and maximum size constraints
-   **Sidebar Navigation**: Clean section switching
-   **Scrollable Content**: Handles varying content lengths

## 🔒 Security & Privacy

### API Key Security

-   **Keychain Storage**: Uses macOS Keychain Services for encryption
-   **Device-Only**: Keys never leave your Mac
-   **Secure Access**: Only this app can access stored keys
-   **Easy Removal**: Clear individual keys or reset all settings

### Privacy Protection

-   **No Telemetry**: No usage data collected or transmitted
-   **Local Processing**: All settings handled locally
-   **No Account Required**: No sign-up or registration needed

## 🛠️ Troubleshooting

### Common Issues

#### Settings Window Won't Open

-   Ensure app has proper permissions
-   Try restarting the application
-   Check Console.app for error messages

#### API Keys Not Saving

-   Verify keychain access permissions
-   Check that keys pass validation
-   Ensure sufficient disk space

#### Services Not Working After Setup

-   Verify API keys are correct and active
-   Check internet connectivity
-   Ensure services are enabled in Music Services tab

### Reset Options

#### Individual Service Reset

-   Go to API Keys tab
-   Click **Clear** next to specific keys
-   Re-enter credentials

#### Complete Reset

-   Click **Reset All Settings** in sidebar
-   Confirms with warning dialog
-   Clears all API keys and preferences
-   Restores default settings

## 🎯 Best Practices

### API Key Management

1. **Keep Keys Secure**: Never share your API keys
2. **Regular Updates**: Regenerate keys periodically for security
3. **Monitor Usage**: Check your API quotas in respective dashboards
4. **Backup Strategy**: Note down keys in secure password manager

### Service Configuration

1. **Start with One**: Configure Spotify first (most reliable)
2. **Test Individually**: Enable one service at a time to test
3. **Monitor Performance**: Disable unused services to improve speed
4. **Check Quotas**: Be aware of API rate limits

## 🆕 What's New

### Enhanced User Experience

-   **No More Hardcoded Keys**: Users provide their own API credentials
-   **Granular Control**: Enable/disable individual services
-   **Secure Storage**: Professional-grade keychain integration
-   **Native Interface**: Follows Apple Human Interface Guidelines

### Developer Benefits

-   **Clean Architecture**: Modular, extensible design
-   **Easy Maintenance**: Centralized settings management
-   **Future-Ready**: Simple to add new music services

---

**🎵 Enjoy your personalized Music Stream Matcher experience! 🎵**

For additional help or questions, check the About section in Settings for more information.
