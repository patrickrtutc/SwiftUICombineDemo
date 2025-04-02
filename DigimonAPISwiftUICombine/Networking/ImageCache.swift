//
//  ImageCache.swift
//  DigimonAPISwiftUICombine
//
//  Created by Patrick Tung on 3/12/25.
//

import SwiftUI
import Combine

/// Actor-based image cache that stores images in memory and on disk
actor ImageCache {
    static let shared = ImageCache() //TODO: make private
    
    // Memory cache using NSCache
    private let memoryCache = NSCache<NSString, UIImage>()
    
    // Configure URLCache for disk caching
    private let urlCache: URLCache = {
        // 50MB memory cache, 100MB disk cache
        let cacheSize = 100 * 1024 * 1024
        let cache = URLCache(memoryCapacity: cacheSize / 2, diskCapacity: cacheSize, diskPath: "digimon_images")
        return cache
    }()
    
    // Reference to CoreDataManager for persistent storage
    private let coreDataManager = CoreDataManager.shared
    
    private init() {
        // Configure memory cache
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
    }
    
    // Get an image from cache or download it
    func image(from url: URL, digimonName: String? = nil) async throws -> UIImage {
        // Generate cache key from URL
        let key = url.absoluteString as NSString
        
        // Check memory cache first (fastest)
        if let cachedImage = memoryCache.object(forKey: key) {
            return cachedImage
        }
        
        // Check CoreData persistent cache if we have a digimon name
        if let name = digimonName, let persistentImage = coreDataManager.getCachedImage(for: name) {
            // Store in memory cache for faster future access
            memoryCache.setObject(persistentImage, forKey: key)
            return persistentImage
        }
        
        // Check disk cache
        if let cachedResponse = urlCache.cachedResponse(for: URLRequest(url: url)),
           let image = UIImage(data: cachedResponse.data) {
            // Store in memory cache for faster future access
            memoryCache.setObject(image, forKey: key)
            return image
        }
        
        // Download the image
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, 
              (200...299).contains(httpResponse.statusCode),
              let image = UIImage(data: data) else {
            throw URLError(.badServerResponse)
        }
        
        // Cache the response
        let cachedResponse = CachedURLResponse(
            response: response,
            data: data,
            userInfo: nil,
            storagePolicy: .allowed
        )
        urlCache.storeCachedResponse(cachedResponse, for: URLRequest(url: url))
        
        // Store in memory cache too
        memoryCache.setObject(image, forKey: key)
        
        return image
    }
    
    // Clear all caches
    func clearCache() {
        memoryCache.removeAllObjects()
        urlCache.removeAllCachedResponses()
    }
}

// MARK: - CachedAsyncImage SwiftUI View
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    private let digimonName: String?
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        digimonName: String? = nil,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.digimonName = digimonName
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            // Skip if no URL or already loading
            guard let url = url, !isLoading else { return }
            
            isLoading = true
            
            do {
                let cachedImage = try await ImageCache.shared.image(from: url, digimonName: digimonName)
                
                withTransaction(transaction) {
                    self.image = cachedImage
                }
            } catch {
                print("Failed to load image: \(error)")
            }
            
            isLoading = false
        }
    }
}

// Convenience extension for easier usage with Digimon model
extension CachedAsyncImage where Content : View, Placeholder : View {
    init(
        digimon: Digimon, 
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.init(
            url: URL(string: digimon.img),
            scale: scale,
            transaction: transaction,
            digimonName: digimon.name,
            content: content,
            placeholder: placeholder
        )
    }
} 
