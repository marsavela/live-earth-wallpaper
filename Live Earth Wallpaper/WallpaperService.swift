//
//  WallpaperService.swift
//  Live Earth Wallpaper
//
//  Created by Sergiu Marsavela on 25/9/25.
//

import Foundation
import AppKit

class WallpaperService {
    
    enum WallpaperError: Error, LocalizedError {
        case failedToSaveImage
        case failedToSetWallpaper
        case noScreensFound
        
        var errorDescription: String? {
            switch self {
            case .failedToSaveImage:
                return "Failed to save wallpaper image to temporary location"
            case .failedToSetWallpaper:
                return "Failed to set desktop wallpaper"
            case .noScreensFound:
                return "No screens found to set wallpaper"
            }
        }
    }
    
    static let shared = WallpaperService()
    
    private let tempDirectory: URL
    
    private init() {
        // Create a temporary directory for wallpaper images
        self.tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LiveEarthWallpaper", isDirectory: true)
        
        // Ensure temp directory exists
        try? FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
    func setWallpaper(_ image: NSImage, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                // Save image to temporary file
                let timestamp = Int(Date().timeIntervalSince1970)
                let imageURL = self.tempDirectory.appendingPathComponent("earth_wallpaper_\(timestamp).jpg")

                guard let tiffData = image.tiffRepresentation,
                      let bitmapImage = NSBitmapImageRep(data: tiffData),
                      let jpegData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else {
                    throw WallpaperError.failedToSaveImage
                }

                try jpegData.write(to: imageURL)

                // Set wallpaper for all screens (must be on main thread)
                DispatchQueue.main.async {
                    self.setWallpaperForAllScreens(imageURL: imageURL, completion: completion)
                }

            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func setWallpaperForAllScreens(imageURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        // IMPORTANT: This function MUST be called on the main thread
        // macOS wallpaper APIs require main thread to properly update all displays
        assert(Thread.isMainThread, "setWallpaperForAllScreens must be called on main thread")

        let screens = NSScreen.screens

        guard !screens.isEmpty else {
            completion(.failure(WallpaperError.noScreensFound))
            return
        }

        var errors: [Error] = []
        let workspace = NSWorkspace.shared

        // Set wallpaper for each screen synchronously on main thread
        // This is required for proper multi-display support
        for screen in screens {
            do {
                let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
                    .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
                    .allowClipping: true
                ]

                try workspace.setDesktopImageURL(
                    imageURL,
                    for: screen,
                    options: options
                )
            } catch {
                errors.append(error)
            }
        }

        // Call completion
        if errors.isEmpty {
            completion(.success(()))
        } else {
            completion(.failure(errors.first ?? WallpaperError.failedToSetWallpaper))
        }
    }
    
    func cleanupOldWallpapers() {
        DispatchQueue.global(qos: .utility).async {
            let fileManager = FileManager.default
            
            do {
                let contents = try fileManager.contentsOfDirectory(
                    at: self.tempDirectory,
                    includingPropertiesForKeys: [.creationDateKey],
                    options: []
                )
                
                let now = Date()
                let oldFileThreshold: TimeInterval = 24 * 60 * 60 // 24 hours
                
                for fileURL in contents {
                    if fileURL.pathExtension.lowercased() == "jpg" {
                        let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                        if let creationDate = attributes[.creationDate] as? Date,
                           now.timeIntervalSince(creationDate) > oldFileThreshold {
                            try fileManager.removeItem(at: fileURL)
                        }
                    }
                }
            } catch {
                print("Error cleaning up old wallpapers: \(error)")
            }
        }
    }
}