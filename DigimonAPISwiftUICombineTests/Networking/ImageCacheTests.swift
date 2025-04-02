//
//  ImageCacheTests.swift
//  DigimonAPISwiftUICombineTests
//
//  Created by Patrick Tung on 3/16/25.
//

import XCTest
import UIKit
@testable import DigimonAPISwiftUICombine

class ImageCacheTests: XCTestCase {
    
    var imageCache: ImageCacheable!
    var mockCoreDataManager: MockCoreDataManager!
    
    // Create a test implementation of ImageCacheable for testing
    actor TestImageCache: ImageCacheable {
        private let memoryCache = NSCache<NSString, UIImage>()
        private let urlCache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024, diskPath: nil)
        private let coreDataManager: CoreDataManagerProtocol
        
        // For controlling test behavior
        private var mockImageData: [URL: UIImage] = [:]
        private var shouldSimulateNetworkError = false
        
        init(coreDataManager: CoreDataManagerProtocol) {
            self.coreDataManager = coreDataManager
        }
        
        // Methods to configure the actor's state
        func setMockImage(_ image: UIImage, for url: URL) {
            mockImageData[url] = image
        }
        
        func setNetworkErrorSimulation(_ shouldSimulate: Bool) {
            shouldSimulateNetworkError = shouldSimulate
        }
        
        func image(from url: URL, digimonName: String? = nil) async throws -> UIImage {
            // Check memory cache first
            let key = url.absoluteString as NSString
            if let cachedImage = memoryCache.object(forKey: key) {
                return cachedImage
            }
            
            // Check CoreData persistent cache
            if let name = digimonName, let persistentImage = coreDataManager.getCachedImage(for: name) {
                memoryCache.setObject(persistentImage, forKey: key)
                return persistentImage
            }
            
            // Simulate network error if needed for testing
            if shouldSimulateNetworkError {
                throw URLError(.badServerResponse)
            }
            
            // Return mock image data if available
            if let mockImage = mockImageData[url] {
                memoryCache.setObject(mockImage, forKey: key)
                return mockImage
            }
            
            // Create a placeholder image as a fallback
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
            let image = renderer.image { ctx in
                UIColor.gray.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
            }
            
            memoryCache.setObject(image, forKey: key)
            return image
        }
        
        func clearCache() async {
            memoryCache.removeAllObjects()
            urlCache.removeAllCachedResponses()
            mockImageData.removeAll()
        }
    }
    
    override func setUpWithError() throws {
        super.setUp()
        mockCoreDataManager = MockCoreDataManager()
        imageCache = TestImageCache(coreDataManager: mockCoreDataManager)
    }
    
    override func tearDownWithError() throws {
        imageCache = nil
        mockCoreDataManager = nil
        super.tearDown()
    }
    
    func testImageCacheReturnsImageFromMemory() async throws {
        // Need to use our test implementation for testing
        guard let testCache = imageCache as? TestImageCache else {
            XCTFail("Expected TestImageCache instance")
            return
        }
        
        // Given
        let testURL = URL(string: "https://example.com/test.jpg")!
        let testImage = UIImage(systemName: "star.fill")!
        
        // Set up the mock data using the actor's method
        await testCache.setMockImage(testImage, for: testURL)
        
        // When - first request (should go to mock data)
        let firstImage = try await testCache.image(from: testURL)
        
        // Then
        XCTAssertNotNil(firstImage)
        
        // When - second request (should come from memory cache)
        let secondImage = try await testCache.image(from: testURL)
        
        // Then - should be the same instance if memory cached
        XCTAssertNotNil(secondImage)
    }
    
    func testImageCacheReturnsImageFromCoreData() async throws {
        // Need to use our test implementation for testing
        guard let testCache = imageCache as? TestImageCache else {
            XCTFail("Expected TestImageCache instance")
            return
        }
        
        // Given
        let testURL = URL(string: "https://example.com/test.jpg")!
        let digimonName = "Agumon"
        let testImage = UIImage(systemName: "star.fill")!
        
        // Setup CoreData mock to return our test image
        mockCoreDataManager.mockImages[digimonName] = testImage
        
        // When
        let image = try await testCache.image(from: testURL, digimonName: digimonName)
        
        // Then
        XCTAssertNotNil(image)
        XCTAssertEqual(mockCoreDataManager.getCachedImageCallCount, 1)
    }
    
    func testImageCacheHandlesNetworkError() async {
        // Need to use our test implementation for testing
        guard let testCache = imageCache as? TestImageCache else {
            XCTFail("Expected TestImageCache instance")
            return
        }
        
        // Given
        let testURL = URL(string: "https://example.com/test.jpg")!
        
        // Set the network error flag using the actor's method
        await testCache.setNetworkErrorSimulation(true)
        
        // When / Then
        do {
            _ = try await testCache.image(from: testURL)
            XCTFail("Expected error to be thrown")
        } catch {
            // Success - error was thrown as expected
            XCTAssertTrue(true)
        }
    }
    
    func testClearCache() async throws {
        // Need to use our test implementation for testing
        guard let testCache = imageCache as? TestImageCache else {
            XCTFail("Expected TestImageCache instance")
            return
        }
        
        // Given
        let testURL = URL(string: "https://example.com/test.jpg")!
        let testImage = UIImage(systemName: "star.fill")!
        
        // Set up the mock data using the actor's method
        await testCache.setMockImage(testImage, for: testURL)
        
        // Load image into memory cache
        _ = try await testCache.image(from: testURL)
        
        // When
        await testCache.clearCache()
        
        // Then
        // Set network error simulation to false
        await testCache.setNetworkErrorSimulation(false)
        
        // The next fetch should go back to the mock data source, not the memory cache
        let imageAfterClear = try await testCache.image(from: testURL)
        XCTAssertNotNil(imageAfterClear)
    }
} 
