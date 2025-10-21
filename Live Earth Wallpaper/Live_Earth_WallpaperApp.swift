//
//  Live_Earth_WallpaperApp.swift
//  Live Earth Wallpaper
//
//  Created by Sergiu Marsavela on 25/9/25.
//

import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Listen for settings open notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openSettingsWindow),
            name: .openSettingsWindow,
            object: nil
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running in background when window is closed
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When app is clicked in dock, show the main window
        for window in sender.windows {
            // Skip settings window
            if window.title.contains("Settings") {
                continue
            }
            // Show the main window
            if window.canBecomeKey {
                window.makeKeyAndOrderFront(nil)
                sender.activate(ignoringOtherApps: true)
                return true
            }
        }
        return true
    }

    @objc private func openSettingsWindow() {
        // Check if settings window already exists
        if let existingWindow = settingsWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        // Find the settings window in existing windows
        for window in NSApp.windows {
            if window.title.contains("Settings") || window.title.contains("Live Earth Wallpaper Settings") {
                window.makeKeyAndOrderFront(nil)
                settingsWindow = window
                return
            }
        }

        // If not found, try to trigger the Settings scene
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)

        // Wait a moment and try to find it again
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            for window in NSApp.windows {
                if window.title.contains("Settings") {
                    self.settingsWindow = window
                    window.makeKeyAndOrderFront(nil)
                    return
                }
            }
        }
    }
}

@main
struct Live_Earth_WallpaperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var menuBarManager: MenuBarManager

    init() {
        let appState = AppState()
        _appState = StateObject(wrappedValue: appState)
        _menuBarManager = StateObject(wrappedValue: MenuBarManager(appState: appState))
    }

    var body: some Scene {
        WindowGroup("Live Earth Wallpaper", id: "main") {
            ContentView()
                .environmentObject(appState)
                .environmentObject(menuBarManager)
        }
        .defaultSize(width: 380, height: 560)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(after: .help) {
                Button("About Live Earth Wallpaper") {
                    NSApplication.shared.orderFrontStandardAboutPanel(nil)
                }
            }
        }
        
        Settings {
            SettingsView(
                apiToken: $appState.storedApiToken,
                imageSize: $appState.imageSize,
                useMarine: $appState.useMarine,
                twilightAngle: $appState.twilightAngle,
                autoRefreshMinutes: $appState.autoRefreshMinutes
            )
        }
        .windowResizability(.contentSize)
    }
}

// Shared app state for settings
class AppState: ObservableObject {
    @AppStorage("api_token") var storedApiToken: String = ""
    @AppStorage("image_size") var imageSize: String = "large"
    @AppStorage("image_quality") var imageQuality: Double = 90
    @AppStorage("use_marine") var useMarine: Bool = true
    @AppStorage("twilight_angle") var twilightAngle: Double = 6.0
    @AppStorage("auto_refresh_minutes") var autoRefreshMinutes: Double = 60
}
