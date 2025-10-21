//
//  ContentView.swift
//  Live Earth Wallpaper
//
//  Created by Sergiu Marsavela on 25/9/25.
//

import SwiftUI
import AppKit
import Combine

class WindowDelegate: NSObject, NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Instead of closing, hide the window
        sender.orderOut(nil)
        return false
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    private var apiService: EarthCompositorAPI? {
        guard !appState.storedApiToken.isEmpty else { return nil }
        return EarthCompositorAPI(apiToken: appState.storedApiToken)
    }

    private var isTokenConfigured: Bool {
        !appState.storedApiToken.isEmpty
    }

    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        }
        return "1.0"
    }

    @State private var lastWallpaperImage: NSImage?
    @State private var statusMessage: String = "Ready to fetch Earth wallpaper"
    @State private var refreshTimer: Timer?
    @State private var nextRefreshDate: Date?
    @State private var windowDelegate = WindowDelegate()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section with Gradient Background
            VStack(spacing: 12) {
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)

                Text("Live Earth Wallpaper")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Real-time day-night Earth composites")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 32)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.05),
                        Color.cyan.opacity(0.03),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Main Content
            VStack(spacing: 20) {
                // Preview area with better styling
                ZStack {
                    if let image = lastWallpaperImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 320, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.gray.opacity(0.1),
                                        Color.gray.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 320, height: 180)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 32))
                                        .foregroundColor(.secondary.opacity(0.5))
                                    Text("No preview available")
                                        .font(.callout)
                                        .foregroundColor(.secondary)
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    }
                }

                // Status and Info Section
                VStack(spacing: 12) {
                    // Status message
                    HStack(spacing: 6) {
                        Circle()
                            .fill(apiService?.isLoading == true ? Color.orange : (lastWallpaperImage != nil ? Color.green : Color.gray))
                            .frame(width: 6, height: 6)

                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.primary.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Token warning
                    if !isTokenConfigured {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("API Token Required")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text("Configure in settings to continue")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Time info
                    VStack(spacing: 8) {
                        if let lastUpdate = apiService?.lastUpdateTime {
                            VStack(spacing: 2) {
                                Text("Last Update")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("\(lastUpdate, style: .relative) ago")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }

                        if let nextRefresh = nextRefreshDate {
                            VStack(spacing: 2) {
                                Text("Next Refresh")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("\(nextRefresh, style: .relative)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // Action buttons
                HStack(spacing: 12) {
                    Button(action: refreshWallpaper) {
                        HStack(spacing: 8) {
                            if apiService?.isLoading == true {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Refresh Now")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isTokenConfigured || apiService?.isLoading == true)
                    .controlSize(.large)

                    Button(action: openPreferences) {
                        Image(systemName: "gearshape.fill")
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(.horizontal, 4)
            }
            .padding(20)
            .padding(.bottom, 8)

            Spacer()

            // Footer with version and author info
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text("v\(appVersion)")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("Made by")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Link("Sergiu Marsavela", destination: URL(string: "https://marsave.la")!)
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 12)
            }
        }
        .frame(width: 380, height: 560)
        .onAppear {
            // Clean up old wallpapers on startup
            WallpaperService.shared.cleanupOldWallpapers()
            // Setup auto-refresh timer
            setupRefreshTimer()
            // Setup window delegate to handle close button
            setupWindowDelegate()
        }
        .onDisappear {
            // Cancel timer when view disappears
            refreshTimer?.invalidate()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshWallpaper)) { _ in
            // Handle refresh request from menu bar
            refreshWallpaper()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettingsWindow)) { _ in
            // Handle settings open request from menu bar
            openPreferences()
        }
        .onChange(of: appState.autoRefreshMinutes) {
            // Restart timer when refresh interval changes
            setupRefreshTimer()
        }
        .onChange(of: appState.storedApiToken) {
            // Restart timer when API token changes
            setupRefreshTimer()
        }
        .alert("Error", isPresented: .constant(apiService?.lastError != nil)) {
            Button("OK") {
                apiService?.lastError = nil
            }
        } message: {
            Text(apiService?.lastError ?? "")
        }
    }

    private func setupWindowDelegate() {
        // Find the main window and set its delegate
        DispatchQueue.main.async {
            if let window = NSApp.windows.first(where: { window in
                !window.title.contains("Settings") && window.canBecomeKey
            }) {
                window.delegate = self.windowDelegate
            }
        }
    }

    private func setupRefreshTimer() {
        // Cancel existing timer
        refreshTimer?.invalidate()
        refreshTimer = nil
        nextRefreshDate = nil

        // Only setup timer if API token is configured
        guard isTokenConfigured else {
            return
        }

        let intervalSeconds = appState.autoRefreshMinutes * 60

        // Calculate next refresh time
        nextRefreshDate = Date().addingTimeInterval(intervalSeconds)

        // Create timer without automatically scheduling it
        refreshTimer = Timer(timeInterval: intervalSeconds, repeats: true) { [appState] _ in
            // Everything must happen on main thread to ensure wallpaper sets correctly on all displays
            DispatchQueue.main.async {
                // Update next refresh date
                nextRefreshDate = Date().addingTimeInterval(TimeInterval(appState.autoRefreshMinutes * 60))

                // Trigger wallpaper refresh using notification
                NotificationCenter.default.post(name: .refreshWallpaper, object: nil)
            }
        }

        // Add timer to main run loop in common mode so it runs even when app is in background
        if let timer = refreshTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func openPreferences() {
        // Try to open using the menu item action
        if let settingsMenuItem = NSApp.mainMenu?.items.first(where: { $0.title == "Live Earth Wallpaper" })?.submenu?.items.first(where: { $0.title.contains("Settings") || $0.title.contains("Preferences") }) {
            NSApp.sendAction(settingsMenuItem.action!, to: settingsMenuItem.target, from: settingsMenuItem)
            return
        }
        
        // Alternative: Force create a new settings window
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 700),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.title = "Settings"
        settingsWindow.contentView = NSHostingView(rootView: SettingsView(
            apiToken: $appState.storedApiToken,
            imageSize: $appState.imageSize,
            useMarine: $appState.useMarine,
            twilightAngle: $appState.twilightAngle,
            autoRefreshMinutes: $appState.autoRefreshMinutes
        ))
        settingsWindow.center()
        settingsWindow.makeKeyAndOrderFront(nil)
        
        // Keep a reference to prevent deallocation
        NSApp.windows.forEach { window in
            if window.title == "Settings" && window != settingsWindow {
                window.close()
            }
        }
    }
    

    
    private func refreshWallpaper() {
        guard isTokenConfigured, let apiService = apiService else {
            statusMessage = "Please configure your API token in settings first."
            return
        }

        statusMessage = "Generating Earth composite..."

        // Update next refresh date when manually refreshing
        if refreshTimer != nil {
            let intervalSeconds = appState.autoRefreshMinutes * 60
            nextRefreshDate = Date().addingTimeInterval(intervalSeconds)
        }

        apiService.fetchEarthComposite(
            marine: appState.useMarine,
            twilightAngle: appState.twilightAngle,
            imageSize: appState.imageSize,
            quality: 100
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    self.lastWallpaperImage = image
                    self.statusMessage = "Setting wallpaper..."

                    WallpaperService.shared.setWallpaper(image) { wallpaperResult in
                        DispatchQueue.main.async {
                            switch wallpaperResult {
                            case .success():
                                self.statusMessage = "Wallpaper updated successfully!"
                            case .failure(let error):
                                self.statusMessage = "Failed to set wallpaper: \(error.localizedDescription)"
                            }
                        }
                    }

                case .failure(let error):
                    self.statusMessage = "Failed to fetch wallpaper: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
