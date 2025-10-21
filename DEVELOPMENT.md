# Development Notes

## Architecture

### Components
- **ContentView**: Main UI with wallpaper preview and controls
- **SettingsView**: Configuration interface
- **MenuBarManager**: Menu bar integration and notifications
- **APIService**: Earth Compositor API communication
- **WallpaperService**: Wallpaper file management and system integration
- **AppState**: Centralized state management using AppStorage

### Key Technical Details

**Multi-Display Support**
- All wallpaper updates must execute on main thread (macOS requirement)
- Uses `RunLoop.main` with `.common` mode for reliable background timers
- Synchronous iteration through `NSScreen.screens`

**File Management**
- Automatic cleanup of wallpapers older than 24 hours
- Temporary directory: `FileManager.temporaryDirectory/LiveEarthWallpaper`

**API Integration**
- Base URL: `https://daynight.sdmn.eu/api/v1/composite`
- Rate limit: 1 request/minute per token
- Network connectivity check before API calls

## Building

### Debug Build
```bash
xcodebuild -project "Live Earth Wallpaper.xcodeproj" \
           -scheme "Live Earth Wallpaper" \
           -configuration Debug \
           build
```

### Release Build
```bash
xcodebuild -project "Live Earth Wallpaper.xcodeproj" \
           -scheme "Live Earth Wallpaper" \
           -configuration Release \
           clean build
```

## Code Conventions

- SwiftUI for modern UI components
- AppKit for system integration (menu bar, wallpaper)
- NotificationCenter for inter-component communication
- AppStorage for persistent configuration
- Comprehensive error handling with proper Result types

## Requirements

- macOS 13.0+ (Ventura)
- Xcode 15.0+
- Swift 5.9+

## Entitlements

- `com.apple.security.app-sandbox`: App Sandbox (enabled)
- `com.apple.security.network.client`: Outgoing network connections (enabled)

---

Built with ❤️ by [Sergiu Marsavela](https://marsave.la)
