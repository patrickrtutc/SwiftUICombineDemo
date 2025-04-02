//
//  CoreDataManagerTests.swift
//  DigimonAPISwiftUICombineTests
//
//  Created by Patrick Tung on 3/16/25.
//

import XCTest
import CoreData
@testable import DigimonAPISwiftUICombine

class CoreDataManagerTests: XCTestCase {
    
    var coreDataManager: CoreDataManagerProtocol!
    var mockContainer: NSPersistentContainer!
    
    override func setUpWithError() throws {
        super.setUp()
        
        // Create an in-memory persistent store for testing
        mockContainer = NSPersistentContainer(name: "DigimonAPISwiftUICombine")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        mockContainer.persistentStoreDescriptions = [description]
        
        mockContainer.loadPersistentStores { (storeDescription, error) in
            XCTAssertNil(error, "Failed to load mock persistent store: \(error?.localizedDescription ?? "")")
        }
        
        coreDataManager = CoreDataManager.shared
    }
    
    override func tearDownWithError() throws {
        coreDataManager.clearAllData()
        coreDataManager = nil
        mockContainer = nil
        super.tearDown()
    }
    
    func testSaveAndFetchDigimons() throws {
        // Given
        let testDigimons = [
            Digimon(name: "Agumon", img: "https://example.com/agumon.jpg", level: "Rookie"),
            Digimon(name: "Gabumon", img: "https://example.com/gabumon.jpg", level: "Rookie")
        ]
        
        // When
        coreDataManager.saveDigimons(testDigimons)
        
        // Need to wait for background context operations to complete
        let expectation = XCTestExpectation(description: "Wait for saveDigimons to complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        let fetchedDigimons = coreDataManager.fetchDigimons()
        
        XCTAssertEqual(fetchedDigimons.count, testDigimons.count)
        
        for digimon in testDigimons {
            let found = fetchedDigimons.contains { fetchedDigimon in
                return fetchedDigimon.name == digimon.name &&
                       fetchedDigimon.img == digimon.img &&
                       fetchedDigimon.level == digimon.level
            }
            XCTAssertTrue(found, "Digimon \(digimon.name) not found in fetched data")
        }
    }
    
    func testClearAllData() throws {
        // Given
        let testDigimons = [
            Digimon(name: "Agumon", img: "https://example.com/agumon.jpg", level: "Rookie"),
            Digimon(name: "Gabumon", img: "https://example.com/gabumon.jpg", level: "Rookie")
        ]
        
        coreDataManager.saveDigimons(testDigimons)
        
        // Need to wait for background operations to complete
        let saveExpectation = XCTestExpectation(description: "Wait for saveDigimons to complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            saveExpectation.fulfill()
        }
        wait(for: [saveExpectation], timeout: 1.0)
        
        // Verify data was saved
        var fetchedDigimons = coreDataManager.fetchDigimons()
        XCTAssertEqual(fetchedDigimons.count, testDigimons.count)
        
        // When
        coreDataManager.clearAllData()
        
        // Need to wait for background operations to complete
        let clearExpectation = XCTestExpectation(description: "Wait for clearAllData to complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            clearExpectation.fulfill()
        }
        wait(for: [clearExpectation], timeout: 1.0)
        
        // Then
        fetchedDigimons = coreDataManager.fetchDigimons()
        XCTAssertEqual(fetchedDigimons.count, 0, "All data should be cleared")
    }
    
    func testFetchDigimonsReturnsEmptyArrayWhenNoData() {
        // Given - fresh database with no data
        
        // When
        let fetchedDigimons = coreDataManager.fetchDigimons()
        
        // Then
        XCTAssertEqual(fetchedDigimons.count, 0, "Should return empty array when no data exists")
    }
    
    // Test for image caching functionality is more complex due to the file system integration
    // Ideally, we would test with a mock file system or isolate the image cache in a separate test
} 
