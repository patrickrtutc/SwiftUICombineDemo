////
////  MockImageCacheTests.swift
////  DigimonAPISwiftUICombineTests
////
////  Created by Patrick Tung on 3/16/25.
////
//
//import XCTest
//import UIKit
//import CoreData
//@testable import DigimonAPISwiftUICombine
//
//class MockImageCacheTests: XCTestCase {
//    
//    var mockImageCache: MockImageCache!
//    
//    override func setUpWithError() throws {
//        super.setUp()
//        mockImageCache = MockImageCache()
//    }
//    
//    override func tearDownWithError() throws {
//        mockImageCache = nil
//        super.tearDown()
//    }
//    
//    func testImageReturnsFromURLCache() async throws {
//        // Given
//        let testURL = URL(string: "https://example.com/test.jpg")!
//        let testImage = UIImage(systemName: "star.fill")!
//        mockImageCache.mockImages[testURL] = testImage
//        
//        // When
//        let image = try await mockImageCache.image(from: testURL)
//        
//        // Then
//        XCTAssertEqual(mockImageCache.imageCallCount, 1)
//        XCTAssertNotNil(image)
//        // Can't directly compare UIImages, but we could check dimensions or other properties
//    }
//    
//    func testImageReturnsFromNamedCache() async throws {
//        // Given
//        let testURL = URL(string: "https://example.com/test.jpg")!
//        let digimonName = "Agumon"
//        let testImage = UIImage(systemName: "heart.fill")!
//        mockImageCache.mockNamedImages[digimonName] = testImage
//        
//        // When
//        let image = try await mockImageCache.image(from: testURL, digimonName: digimonName)
//        
//        // Then
//        XCTAssertEqual(mockImageCache.imageCallCount, 1)
//        XCTAssertNotNil(image)
//    }
//    
//    func testImageThrowsErrorWhenConfigured() async {
//        // Given
//        let testURL = URL(string: "https://example.com/test.jpg")!
//        mockImageCache.shouldThrowError = true
//        
//        // When/Then
//        do {
//            _ = try await mockImageCache.image(from: testURL)
//            XCTFail("Expected error to be thrown")
//        } catch {
//            XCTAssertEqual(mockImageCache.imageCallCount, 1)
//            XCTAssertEqual((error as NSError).domain, "MockImageCache")
//        }
//    }
//    
//    func testImageFallbackWhenNoMatchingImageFound() async throws {
//        // Given
//        let testURL = URL(string: "https://example.com/nonexistent.jpg")!
//        
//        // When
//        let image = try await mockImageCache.image(from: testURL)
//        
//        // Then
//        XCTAssertEqual(mockImageCache.imageCallCount, 1)
//        XCTAssertNotNil(image)
//        // The fallback is a 1x1 gray image
//        XCTAssertEqual(image.size.width, 1)
//        XCTAssertEqual(image.size.height, 1)
//    }
//    
//    func testClearCache() async {
//        // Given
//        let testURL = URL(string: "https://example.com/test.jpg")!
//        let testImage = UIImage(systemName: "star.fill")!
//        mockImageCache.mockImages[testURL] = testImage
//        
//        let digimonName = "Agumon"
//        let namedImage = UIImage(systemName: "heart.fill")!
//        mockImageCache.mockNamedImages[digimonName] = namedImage
//        
//        // When
//        await mockImageCache.clearCache()
//        
//        // Then
//        XCTAssertEqual(mockImageCache.clearCacheCallCount, 1)
//        XCTAssertTrue(mockImageCache.mockImages.isEmpty)
//        XCTAssertTrue(mockImageCache.mockNamedImages.isEmpty)
//    }
//    
//    func testInMemoryContainer() {
//        // Get the mockCoreDataManager to test its container
//        let mockCoreDataManager = MockCoreDataManager()
//        
//        // Verify the mock uses an in-memory container
//        XCTAssertEqual(mockCoreDataManager.container.persistentStoreDescriptions.first?.type, NSInMemoryStoreType)
//    }
//} 
