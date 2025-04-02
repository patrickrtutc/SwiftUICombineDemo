//
//  MockCoreDataManager.swift
//  DigimonAPISwiftUICombineTests
//
//  Created by Patrick Tung on 3/16/25.
//

import Foundation
import UIKit
import CoreData
@testable import DigimonAPISwiftUICombine

class MockCoreDataManager: CoreDataManagerProtocol {
    // Test container that loads in-memory stores
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DigimonAPISwiftUICombine")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load in-memory persistent stores: \(error)")
            }
        }
        return container
    }()
    
    // For validation in tests
    var savedDigimons: [Digimon] = []
    var fetchDigimonsCallCount = 0
    var getCachedImageCallCount = 0
    var clearAllDataCallCount = 0
    
    // Mock data to return
    var mockDigimons: [Digimon] = []
    var mockImages: [String: UIImage] = [:]
    
    func saveDigimons(_ digimons: [Digimon]) {
        savedDigimons = digimons
    }
    
    func fetchDigimons() -> [Digimon] {
        fetchDigimonsCallCount += 1
        return mockDigimons
    }
    
    func getCachedImage(for digimonName: String) -> UIImage? {
        getCachedImageCallCount += 1
        return mockImages[digimonName]
    }
    
    func clearAllData() {
        clearAllDataCallCount += 1
        savedDigimons = []
    }
}