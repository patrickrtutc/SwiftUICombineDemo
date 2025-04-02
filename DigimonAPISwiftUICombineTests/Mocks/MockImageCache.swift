//
//  MockImageCache.swift
//  DigimonAPISwiftUICombineTests
//
//  Created by Patrick Tung on 3/16/25.
//

import Foundation
import UIKit
@testable import DigimonAPISwiftUICombine

actor MockImageCache: ImageCacheable {
    // For validation in tests
    var imageCallCount = 0
    var clearCacheCallCount = 0
    
    // Mock data to return
    var mockImages: [URL: UIImage] = [:]
    var mockNamedImages: [String: UIImage] = [:]
    
    // Error to throw if needed
    var shouldThrowError = false
    var mockError = NSError(domain: "MockImageCache", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    
    // Methods to configure the mock from outside the actor
    func setMockImage(for url: URL, image: UIImage) {
        mockImages[url] = image
    }
    
    func setMockImage(for name: String, image: UIImage) {
        mockNamedImages[name] = image
    }
    
    func setMockImage(for url: URL, name: String, image: UIImage) {
        mockImages[url] = image
        mockNamedImages[name] = image
    }
    
    func image(from url: URL, digimonName: String? = nil) async throws -> UIImage {
        imageCallCount += 1
        
        if shouldThrowError {
            throw mockError
        }
        
        // First check if we have an image for the given URL
        if let image = mockImages[url] {
            return image
        }
        
        // If not, check if we have an image for the given name
        if let name = digimonName, let image = mockNamedImages[name] {
            return image
        }
        
        // If we don't have any matching image, create a dummy 1x1 image
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        return renderer.image { context in
            UIColor.gray.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }
    
    func clearCache() async {
        clearCacheCallCount += 1
        mockImages.removeAll()
        mockNamedImages.removeAll()
    }
    
    // Helper methods for repository tests
    func getImageCallCount() -> Int {
        return imageCallCount
    }
} 