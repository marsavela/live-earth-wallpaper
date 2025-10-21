//
//  APIService.swift
//  Live Earth Wallpaper
//
//  Created by Sergiu Marsavela on 25/9/25.
//

import Foundation
import SwiftUI
import Combine
import Network

// MARK: - API Models

struct CompositeRequest: Codable {
    let datetime: String?
    let marine: Bool
    let twilightAngle: Double
    let blurRadius: Double
    let resize: String
    let quality: Int
    let outputFormat: String
    let force: Bool
    
    enum CodingKeys: String, CodingKey {
        case datetime
        case marine
        case twilightAngle = "twilight_angle"
        case blurRadius = "blur_radius"
        case resize
        case quality
        case outputFormat = "output_format"
        case force
    }
}

struct CompositeResponse: Codable {
    let image: String // base64 encoded image data
    let success: Bool
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case image = "image_data"
        case success
        case message
    }
}



struct APIError: Codable {
    let error: String
    let message: String
    let retryAfter: Int?
    
    enum CodingKeys: String, CodingKey {
        case error
        case message
        case retryAfter = "retry_after"
    }
}

// MARK: - API Configuration

struct APIConfiguration {
    static let baseURL = "https://daynight.sdmn.eu"
    static let compositeEndpoint = "/api/v1/composite"

    // Default settings for wallpaper generation
    static let defaultRequest = CompositeRequest(
        datetime: nil,
        marine: true,
        twilightAngle: 6.0,
        blurRadius: 0.0,
        resize: "small",
        quality: 90,
        outputFormat: "jpeg",
        force: false
    )
}

// MARK: - API Service

class EarthCompositorAPI: ObservableObject {
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var lastUpdateTime: Date?
    
    private let apiToken: String
    private let session: URLSession
    
    init(apiToken: String) {
        self.apiToken = apiToken
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120 // 2 minutes timeout for image generation
        config.timeoutIntervalForResource = 180 // 3 minutes total timeout
        self.session = URLSession(configuration: config)
    }
    
    func fetchEarthComposite(
        marine: Bool = true,
        twilightAngle: Double = 6.0,
        imageSize: String = "large",
        quality: Int = 90,
        completion: @escaping (Result<NSImage, Error>) -> Void
    ) {
        print("🌍 fetchEarthComposite called with:")
        print("  - marine: \(marine)")
        print("  - twilightAngle: \(twilightAngle)")  
        print("  - imageSize: \(imageSize)")
        print("  - quality: \(quality)")
        
        // Check network connectivity first
        let pathMonitor = NWPathMonitor()
        pathMonitor.pathUpdateHandler = { path in
            print("🌐 Network status: \(path.status)")
            if path.status != .satisfied {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.lastError = "No internet connection available"
                }
                completion(.failure(APIServiceError.noInternet))
                pathMonitor.cancel()
                return
            }
            pathMonitor.cancel()
            
            // Proceed with API call after network check
            self.performAPICall(
                marine: marine,
                twilightAngle: twilightAngle,
                imageSize: imageSize,
                quality: quality,
                completion: completion
            )
        }
        pathMonitor.start(queue: DispatchQueue.global())
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.lastError = nil
        }
    }
    
    private func performAPICall(
        marine: Bool,
        twilightAngle: Double,
        imageSize: String,
        quality: Int,
        completion: @escaping (Result<NSImage, Error>) -> Void
    ) {
        let request = CompositeRequest(
            datetime: nil,
            marine: marine,
            twilightAngle: twilightAngle,
            blurRadius: 0.0,
            resize: imageSize,
            quality: quality,
            outputFormat: "jpeg",
            force: false
        )
        
        guard let url = URL(string: APIConfiguration.baseURL + APIConfiguration.compositeEndpoint) else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.lastError = "Invalid API URL configuration"
            }
            completion(.failure(APIServiceError.invalidURL))
            return
        }
        
        // Test DNS resolution first
        let host = NWEndpoint.Host(url.host ?? "daynight.sdmn.eu")
        let connection = NWConnection(host: host, port: .https, using: .tls)
        
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                connection.cancel()
                // DNS resolution successful, proceed with HTTP request
                self.performHTTPRequest(url: url, request: request, completion: completion)
            case .failed(let error):
                DispatchQueue.main.async {
                    self.isLoading = false
                    if error.localizedDescription.contains("DNS") || error.localizedDescription.contains("resolve") {
                        self.lastError = "Cannot resolve daynight.sdmn.eu. Please check your DNS settings or try again later."
                    } else {
                        self.lastError = "Cannot connect to daynight.sdmn.eu: \(error.localizedDescription)"
                    }
                }
                connection.cancel()
                completion(.failure(error))
            default:
                break
            }
        }
        
        connection.start(queue: DispatchQueue.global())
    }
    
    private func performHTTPRequest(
        url: URL,
        request: CompositeRequest,
        completion: @escaping (Result<NSImage, Error>) -> Void
    ) {
        
        print("🔗 Making HTTP request to: \(url)")
        print("🔑 Using token: \(String(apiToken.prefix(10)))...")
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.lastError = "Failed to encode request: \(error.localizedDescription)"
            }
            completion(.failure(error))
            return
        }
        
        session.dataTask(with: urlRequest) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    // More specific error messages
                    let errorDescription = error.localizedDescription.lowercased()
                    if errorDescription.contains("could not be found") || errorDescription.contains("hostname") {
                        self?.lastError = "Cannot reach daynight.sdmn.eu. Please check your internet connection and try again."
                    } else if errorDescription.contains("network") || errorDescription.contains("connection") {
                        self?.lastError = "Network connection failed. Please check your internet connection."
                    } else if errorDescription.contains("timeout") {
                        self?.lastError = "Request timed out. The server may be busy, please try again."
                    } else {
                        self?.lastError = "Connection error: \(error.localizedDescription)"
                    }
                }
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self?.lastError = "No data received from server"
                }
                completion(.failure(APIServiceError.noData))
                return
            }
            
            // Check HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 429 {
                    // Rate limit exceeded
                    if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                        DispatchQueue.main.async {
                            self?.lastError = "Rate limit exceeded: \(apiError.message)"
                        }
                        completion(.failure(APIServiceError.rateLimitExceeded(apiError)))
                    } else {
                        DispatchQueue.main.async {
                            self?.lastError = "Rate limit exceeded"
                        }
                        completion(.failure(APIServiceError.rateLimitExceeded(nil)))
                    }
                    return
                } else if httpResponse.statusCode >= 400 {
                    // Other client/server errors
                    if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                        DispatchQueue.main.async {
                            self?.lastError = "API error: \(apiError.message)"
                        }
                        completion(.failure(APIServiceError.apiError(apiError)))
                    } else {
                        DispatchQueue.main.async {
                            self?.lastError = "Server error: HTTP \(httpResponse.statusCode)"
                        }
                        completion(.failure(APIServiceError.httpError(httpResponse.statusCode)))
                    }
                    return
                }
            }
            
            // Parse successful response - DEBUG VERSION
            DispatchQueue.main.async {
                self?.lastError = "DEBUG: Processing \(data.count) byte response..."
            }
            
            do {
                NSLog("[LIVE_EARTH_WALLPAPER] Raw API response size: \(data.count) bytes")
                print("[LIVE_EARTH_WALLPAPER] Raw API response size: \(data.count) bytes")
                
                // First, let's see what the raw response looks like
                if let responseString = String(data: data, encoding: .utf8) {
                    let preview = String(responseString.prefix(500))
                    NSLog("[LIVE_EARTH_WALLPAPER] Response preview: \(preview)")
                    print("[LIVE_EARTH_WALLPAPER] Response preview: \(preview)")
                    
                    // Try to identify the structure
                    if responseString.contains("\"image\"") {
                        NSLog("[LIVE_EARTH_WALLPAPER] Response contains 'image' field")
                        print("[LIVE_EARTH_WALLPAPER] Response contains 'image' field")
                    } else {
                        NSLog("[LIVE_EARTH_WALLPAPER] ERROR: No 'image' field found!")
                        print("[LIVE_EARTH_WALLPAPER] ERROR: No 'image' field found!")
                        DispatchQueue.main.async {
                            self?.lastError = "DEBUG ERROR: No 'image' field in response"
                        }
                    }
                    if responseString.contains("\"metadata\"") {
                        NSLog("[LIVE_EARTH_WALLPAPER] Response contains 'metadata' field")
                        print("[LIVE_EARTH_WALLPAPER] Response contains 'metadata' field")
                    }
                }
                
                let compositeResponse = try JSONDecoder().decode(CompositeResponse.self, from: data)
                NSLog("[LIVE_EARTH_WALLPAPER] Successfully parsed API response")
                print("[LIVE_EARTH_WALLPAPER] Successfully parsed API response")
                
                DispatchQueue.main.async {
                    self?.lastError = "DEBUG: JSON parsed successfully"
                }
                
                // Convert base64 image data to NSImage
                let imageData = compositeResponse.image
                NSLog("[LIVE_EARTH_WALLPAPER] Image data length: \(imageData.count)")
                print("[LIVE_EARTH_WALLPAPER] Image data length: \(imageData.count)")
                let base64String = imageData.hasPrefix("data:image/") ? 
                    String(imageData.split(separator: ",")[1]) : imageData
                
                guard let imageDataDecoded = Data(base64Encoded: base64String),
                      let image = NSImage(data: imageDataDecoded) else {
                    DispatchQueue.main.async {
                        self?.lastError = "Failed to decode image data"
                    }
                    completion(.failure(APIServiceError.imageDecodingFailed))
                    return
                }
                
                DispatchQueue.main.async {
                    self?.lastUpdateTime = Date()
                }
                
                completion(.success(image))
                
            } catch {
                NSLog("[LIVE_EARTH_WALLPAPER] ERROR: JSON parsing failed: \(error)")
                print("[LIVE_EARTH_WALLPAPER] ERROR: JSON parsing failed: \(error)")
                
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        let errorMsg = "Missing key '\(key.stringValue)' at \(context.codingPath)"
                        NSLog("[LIVE_EARTH_WALLPAPER] ERROR: \(errorMsg)")
                        print("[LIVE_EARTH_WALLPAPER] ERROR: \(errorMsg)")
                        DispatchQueue.main.async {
                            self?.lastError = "DEBUG ERROR: \(errorMsg)"
                        }
                    case .typeMismatch(let type, let context):
                        let errorMsg = "Type mismatch for \(type) at \(context.codingPath)"
                        NSLog("[LIVE_EARTH_WALLPAPER] ERROR: \(errorMsg)")
                        print("[LIVE_EARTH_WALLPAPER] ERROR: \(errorMsg)")
                        DispatchQueue.main.async {
                            self?.lastError = "DEBUG ERROR: \(errorMsg)"
                        }
                    case .valueNotFound(let type, let context):
                        let errorMsg = "Value not found for \(type) at \(context.codingPath)"
                        NSLog("[LIVE_EARTH_WALLPAPER] ERROR: \(errorMsg)")
                        print("[LIVE_EARTH_WALLPAPER] ERROR: \(errorMsg)")
                        DispatchQueue.main.async {
                            self?.lastError = "DEBUG ERROR: \(errorMsg)"
                        }
                    case .dataCorrupted(let context):
                        let errorMsg = "Data corrupted at \(context.codingPath): \(context.debugDescription)"
                        NSLog("[LIVE_EARTH_WALLPAPER] ERROR: \(errorMsg)")
                        print("[LIVE_EARTH_WALLPAPER] ERROR: \(errorMsg)")
                        DispatchQueue.main.async {
                            self?.lastError = "DEBUG ERROR: \(errorMsg)"
                        }
                    @unknown default:
                        let errorMsg = "Unknown decoding error: \(decodingError)"
                        NSLog("[LIVE_EARTH_WALLPAPER] ERROR: \(errorMsg)")
                        print("[LIVE_EARTH_WALLPAPER] ERROR: \(errorMsg)")
                        DispatchQueue.main.async {
                            self?.lastError = "DEBUG ERROR: \(errorMsg)"
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.lastError = "DEBUG ERROR: \(error.localizedDescription)"
                    }
                }
                
                DispatchQueue.main.async {
                    self?.lastError = "Failed to parse response: \(error.localizedDescription)"
                }
                completion(.failure(error))
            }
            
        }.resume()
    }
}

// MARK: - Error Types

enum APIServiceError: Error, LocalizedError {
    case invalidURL
    case noData
    case noInternet
    case imageDecodingFailed
    case rateLimitExceeded(APIError?)
    case apiError(APIError)
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noData:
            return "No data received from server"
        case .noInternet:
            return "No internet connection available"
        case .imageDecodingFailed:
            return "Failed to decode image data"
        case .rateLimitExceeded(let apiError):
            return apiError?.message ?? "Rate limit exceeded. Please try again later."
        case .apiError(let apiError):
            return apiError.message
        case .httpError(let code):
            return "Server returned error code: \(code)"
        }
    }
}