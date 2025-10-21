# Live Earth Wallpaper

A beautiful macOS menu bar application that automatically updates your desktop wallpaper with real-time day-night Earth composite images.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## Features

- 🌍 **Real-time Earth Composites**: Beautiful day-night boundary visualizations
- 🖥️ **Multi-Display Support**: Automatically updates all connected displays
- ⏰ **Auto-Refresh**: Configurable automatic wallpaper updates (15 min to 6 hours)
- 🎨 **Customizable Settings**:
  - Image size (small, medium, large, full)
  - Marine bathymetry overlay
  - Twilight angle adjustment (0° to 18°)
- 📊 **Menu Bar Integration**: Quick access from the menu bar
- 🔒 **Sandboxed**: Runs securely in the macOS App Sandbox
- 🌙 **Background Operation**: Continues updating even when window is closed

## Screenshots

### Main Window
The main window shows a preview of the current wallpaper with refresh controls and settings access.

### Settings
Configure your API token, image preferences, and automatic refresh interval.

## Requirements

- macOS 13.0 (Ventura) or later
- API token from [daynight.sdmn.eu](https://daynight.sdmn.eu)

## Installation

### From Source

1. Clone the repository:
```bash
git clone https://github.com/marsavela/live-earth-wallpaper.git
cd live-earth-wallpaper
```

2. Open the project in Xcode:
```bash
open "Live Earth Wallpaper.xcodeproj"
```

3. Build and run the project (⌘+R)

## Configuration

### API Token Setup

1. Launch the app
2. Click the gear icon or select "Settings" from the menu bar
3. Enter your API token from the Earth Compositor API
4. Configure your preferred settings

### Settings Options

- **API Token**: Your authentication token for the Earth Compositor API
- **Image Size**: Choose from small, medium, large, or full resolution
- **Marine Bathymetry**: Toggle ocean depth visualization
- **Twilight Angle**: Adjust the day-night boundary visualization (0° = no twilight, 18° = astronomical twilight)
- **Auto Refresh Interval**: Set how often to update (15 minutes to 6 hours)

## Usage

### Menu Bar

The app lives in your menu bar with a globe icon. Click it to:
- Refresh wallpaper immediately
- Show the main window
- Open settings
- View about information
- Quit the application

### Keyboard Shortcuts

- `⌘,` - Open Settings
- `⌘R` - Refresh Wallpaper (when menu is open)
- `⌘Q` - Quit Application (when menu is open)

## Architecture

### Components

- **ContentView**: Main UI with wallpaper preview and controls
- **SettingsView**: Configuration interface for all app settings
- **MenuBarManager**: Handles menu bar integration and notifications
- **APIService**: Manages communication with the Earth Compositor API
- **WallpaperService**: Handles wallpaper file management and system integration
- **AppState**: Centralized state management using AppStorage

### Key Technical Details

- **Threading**: All wallpaper updates execute on the main thread to ensure proper multi-display support
- **Timer Management**: Uses RunLoop.main with .common mode for reliable background operation
- **Notification System**: Decoupled architecture using NotificationCenter for inter-component communication
- **File Management**: Automatic cleanup of old wallpaper files (24-hour retention)

## API Integration

This app integrates with the Earth Compositor API at `https://daynight.sdmn.eu`. The API generates composite Earth images showing:
- Current day-night boundary
- Optional marine bathymetry
- Configurable twilight zones
- Multiple resolution options

**API Rate Limit**: 1 request per minute per token

## Development

### Building

```bash
xcodebuild -project "Live Earth Wallpaper.xcodeproj" -scheme "Live Earth Wallpaper" -configuration Release build
```

### Code Structure

```
Live Earth Wallpaper/
├── APIService.swift           # API communication layer
├── ContentView.swift          # Main application window
├── SettingsView.swift         # Settings configuration UI
├── MenuBarManager.swift       # Menu bar integration
├── WallpaperService.swift     # Wallpaper system integration
├── Live_Earth_WallpaperApp.swift  # App entry point and state
└── Assets.xcassets/           # App icons and assets
```

### Entitlements

The app requires the following entitlements:
- `com.apple.security.app-sandbox`: App Sandbox
- `com.apple.security.network.client`: Outgoing network connections

## Troubleshooting

### Wallpaper not updating automatically
- Check that auto-refresh is enabled in Settings
- Verify your API token is valid
- Ensure you have an active internet connection
- Check Console.app for any error messages

### Only main display updates
- This was a known issue that has been fixed
- Ensure you're running the latest version
- The app must run on the main thread for multi-display support

### API token not saving
- Check that you've entered the token correctly
- Settings are stored in UserDefaults and persist across launches

## Privacy & Security

- **No Data Collection**: This app does not collect any user data
- **Secure Storage**: API tokens are stored in UserDefaults (sandboxed)
- **Network Usage**: Only connects to the Earth Compositor API
- **Sandboxed**: Runs in the macOS App Sandbox for security

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Earth Compositor API by [Sergiu Marsavela](https://marsave.la)
- Built with SwiftUI and AppKit
- Inspired by the beauty of our planet

## Author

**Sergiu Marsavela**
- Website: [marsave.la](https://marsave.la)
- GitHub: [@marsavela](https://github.com/marsavela)

## Version History

### 1.0.0 (2024-10-20)
- Initial release
- Multi-display support
- Auto-refresh functionality
- Menu bar integration
- Customizable settings
- Secure API token management

---

Made with ❤️ by [Sergiu Marsavela](https://marsave.la)
