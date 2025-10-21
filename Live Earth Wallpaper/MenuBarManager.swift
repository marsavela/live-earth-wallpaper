//
//  MenuBarManager.swift
//  Live Earth Wallpaper
//
//  Created by Claude Code on 19/10/25.
//

import SwiftUI
import AppKit
import Combine

class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var appState: AppState

    @Published var isRefreshing = false

    init(appState: AppState) {
        self.appState = appState
        setupMenuBar()
    }

    private func setupMenuBar() {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "globe.americas.fill", accessibilityDescription: "Live Earth Wallpaper")
            button.image?.isTemplate = true
        }

        // Create menu
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Live Earth Wallpaper", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        let refreshItem = NSMenuItem(title: "Refresh Wallpaper Now", action: #selector(refreshWallpaper), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        let showWindowItem = NSMenuItem(title: "Show Window", action: #selector(showMainWindow), keyEquivalent: "")
        showWindowItem.target = self
        menu.addItem(showWindowItem)

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let aboutItem = NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Live Earth Wallpaper", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func refreshWallpaper() {
        guard !isRefreshing else { return }
        isRefreshing = true

        // Post notification to trigger refresh in ContentView
        NotificationCenter.default.post(name: .refreshWallpaper, object: nil)

        // Reset after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isRefreshing = false
        }
    }

    @objc private func showMainWindow() {
        // Activate app first
        NSApp.activate(ignoringOtherApps: true)

        // Find the main window - now windows are hidden, not closed
        for window in NSApp.windows {
            // Skip settings window and status bar items
            if window.title.contains("Settings") || window.className.contains("StatusBar") {
                continue
            }
            // Found main window - show it
            if window.canBecomeKey {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)

        // Post notification to open settings
        NotificationCenter.default.post(name: .openSettingsWindow, object: nil)
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

// Notification names
extension Notification.Name {
    static let refreshWallpaper = Notification.Name("refreshWallpaper")
    static let showMainWindow = Notification.Name("showMainWindow")
    static let openSettingsWindow = Notification.Name("openSettingsWindow")
}
