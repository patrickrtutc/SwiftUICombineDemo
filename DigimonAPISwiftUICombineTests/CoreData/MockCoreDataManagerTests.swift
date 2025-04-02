//
//  MockCoreDataManagerTests.swift
//  DigimonAPISwiftUICombineTests
//
//  Created by Patrick Tung on 3/16/25.
//

import XCTest
import UIKit
import CoreData
@testable import DigimonAPISwiftUICombine

class MockCoreDataManagerTests: XCTestCase {
    
    var mockCoreDataManager: MockCoreDataManager!
    
    override func setUpWithError() throws {
        super.setUp()
        mockCoreDataManager = MockCoreDataManager()
    }
    
    override func tearDownWithError() throws {
        mockCoreDataManager = nil
        super.tearDown()
    }
    
    func testSaveDigimons() {
        // Given
        let testDigimons = [
            Digimon(name: "Agumon", img: "https://example.com/agumon.jpg", level: "Rookie"),
            Digimon(name: "Gabumon", img: "https://example.com/gabumon.jpg", level: "Rookie")
        ]
        
        // When
        mockCoreDataManager.saveDigimons(testDigimons)
        
        // Then
        XCTAssertEqual(mockCoreDataManager.savedDigimons.count, testDigimons.count)
        
        for (i, digimon) in testDigimons.enumerated() {
            XCTAssertEqual(mockCoreDataManager.savedDigimons[i].name, digimon.name)
            XCTAssertEqual(mockCoreDataManager.savedDigimons[i].img, digimon.img)
            XCTAssertEqual(mockCoreDataManager.savedDigimons[i].level, digimon.level)
        }
    }
    
    func testFetchDigimons() {
        // Given
        let testDigimons = [
            Digimon(name: "Agumon", img: "https://example.com/agumon.jpg", level: "Rookie"),
            Digimon(name: "Gabumon", img: "https://example.com/gabumon.jpg", level: "Rookie")
        ]
        mockCoreDataManager.mockDigimons = testDigimons
        
        // When
        let fetchedDigimons = mockCoreDataManager.fetchDigimons()
        
        // Then
        XCTAssertEqual(mockCoreDataManager.fetchDigimonsCallCount, 1)
        XCTAssertEqual(fetchedDigimons.count, testDigimons.count)
        
        for (i, digimon) in testDigimons.enumerated() {
            XCTAssertEqual(fetchedDigimons[i].name, digimon.name)
            XCTAssertEqual(fetchedDigimons[i].img, digimon.img)
            XCTAssertEqual(fetchedDigimons[i].level, digimon.level)
        }
    }
    
    func testGetCachedImage() {
        // Given
        let testImage = UIImage(systemName: "star.fill")!
        let digimonName = "Agumon"
        mockCoreDataManager.mockImages[digimonName] = testImage
        
        // When
        let cachedImage = mockCoreDataManager.getCachedImage(for: digimonName)
        
        // Then
        XCTAssertEqual(mockCoreDataManager.getCachedImageCallCount, 1)
        XCTAssertNotNil(cachedImage)
        // Since UIImage doesn't conform to Equatable, we can check that it exists
        // A more thorough test would compare image data
    }
    
    func testGetCachedImageReturnsNilWhenNotFound() {
        // Given
        let digimonName = "NonExistentDigimon"
        
        // When
        let cachedImage = mockCoreDataManager.getCachedImage(for: digimonName)
        
        // Then
        XCTAssertEqual(mockCoreDataManager.getCachedImageCallCount, 1)
        XCTAssertNil(cachedImage)
    }
    
    func testClearAllData() {
        // Given
        let testDigimons = [
            Digimon(name: "Agumon", img: "https://example.com/agumon.jpg", level: "Rookie"),
            Digimon(name: "Gabumon", img: "https://example.com/gabumon.jpg", level: "Rookie")
        ]
        mockCoreDataManager.savedDigimons = testDigimons
        
        // When
        mockCoreDataManager.clearAllData()
        
        // Then
        XCTAssertEqual(mockCoreDataManager.clearAllDataCallCount, 1)
        XCTAssertEqual(mockCoreDataManager.savedDigimons.count, 0)
    }
    
    func testInMemoryContainer() {
        // Verify the mock uses an in-memory container
        XCTAssertEqual(mockCoreDataManager.container.persistentStoreDescriptions.first?.type, NSInMemoryStoreType)
    }
} 
