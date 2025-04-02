//
//  MockDigimonRepository.swift
//  DigimonAPISwiftUICombineTests
//
//  Created by Patrick Tung on 3/14/25.
//

import Foundation
import Combine
import UIKit
@testable import DigimonAPISwiftUICombine

class MockDigimonRepository: DigimonRepository {
    // Test configuration
    var shouldReturnError = false
    var shouldReturnEmpty = false
    var mockDataFileName = "mockDigimon"
    var mockDataSource: DataSource = .cache
    var mockImage: UIImage? = UIImage(systemName: "photo")
    var loadDelay: TimeInterval = 0
    
    // Monitor calls for verification
    var fetchAllCallCount = 0
    var fetchByLevelCallCount = 0
    var fetchByNameCallCount = 0
    var getImageCallCount = 0
    var refreshDataCallCount = 0
    var lastFetchedLevel: String?
    var lastFetchedName: String?
    var lastImageDigimon: Digimon?
    
    // Publisher for data source changes (simulating DefaultDigimonRepository)
    let dataSourceSubject = CurrentValueSubject<DataSource?, Never>(nil)
    var dataSourcePublisher: AnyPublisher<DataSource?, Never> {
        return dataSourceSubject.eraseToAnyPublisher()
    }
    
    private var mockData: [Digimon]? = nil
    
    init() {
        // Load mock data once to make tests faster
        loadMockData()
    }
    
    private func loadMockData() {
        let bundle = Bundle(for: MockDigimonRepository.self)
        if let path = bundle.url(forResource: mockDataFileName, withExtension: "json"),
           let data = try? Data(contentsOf: path),
           let parsedData = try? JSONDecoder().decode([Digimon].self, from: data) {
            mockData = parsedData
        }
    }
    
    func fetchAllDigimons() -> AnyPublisher<[Digimon], Error> {
        fetchAllCallCount += 1
        
        if shouldReturnError {
            return Fail(error: NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Test error"]))
                .delay(for: .seconds(loadDelay), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        if shouldReturnEmpty {
            dataSourceSubject.send(mockDataSource)
            return Just([])
                .setFailureType(to: Error.self)
                .delay(for: .seconds(loadDelay), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        guard let mockData = mockData else {
            return Fail(error: NSError(domain: "test", code: 404, userInfo: [NSLocalizedDescriptionKey: "Could not load mock data"]))
                .eraseToAnyPublisher()
        }
        
        dataSourceSubject.send(mockDataSource)
        return Just(mockData)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(loadDelay), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func fetchDigimonsByLevel(_ level: String) -> AnyPublisher<[Digimon], Error> {
        fetchByLevelCallCount += 1
        lastFetchedLevel = level
        
        if shouldReturnError {
            return Fail(error: NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Test error"]))
                .delay(for: .seconds(loadDelay), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        if shouldReturnEmpty {
            dataSourceSubject.send(mockDataSource)
            return Just([])
                .setFailureType(to: Error.self)
                .delay(for: .seconds(loadDelay), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        guard let mockData = mockData else {
            return Fail(error: NSError(domain: "test", code: 404, userInfo: [NSLocalizedDescriptionKey: "Could not load mock data"]))
                .eraseToAnyPublisher()
        }
        
        let filteredData = mockData.filter { $0.level == level }
        dataSourceSubject.send(mockDataSource)
        return Just(filteredData)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(loadDelay), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func fetchDigimonsByName(_ name: String) -> AnyPublisher<[Digimon], Error> {
        fetchByNameCallCount += 1
        lastFetchedName = name
        
        if shouldReturnError {
            return Fail(error: NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Test error"]))
                .delay(for: .seconds(loadDelay), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        if shouldReturnEmpty {
            dataSourceSubject.send(mockDataSource)
            return Just([])
                .setFailureType(to: Error.self)
                .delay(for: .seconds(loadDelay), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        guard let mockData = mockData else {
            return Fail(error: NSError(domain: "test", code: 404, userInfo: [NSLocalizedDescriptionKey: "Could not load mock data"]))
                .eraseToAnyPublisher()
        }
        
        let filteredData = mockData.filter { $0.name.lowercased().contains(name.lowercased()) }
        dataSourceSubject.send(mockDataSource)
        return Just(filteredData)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(loadDelay), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func getImage(for digimon: Digimon) -> AnyPublisher<UIImage?, Error> {
        getImageCallCount += 1
        lastImageDigimon = digimon
        
        if shouldReturnError {
            return Fail(error: NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Test error"]))
                .delay(for: .seconds(loadDelay), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        return Just(mockImage)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(loadDelay), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func refreshData() -> AnyPublisher<[Digimon], Error> {
        refreshDataCallCount += 1
        // Reuse fetchAllDigimons but set data source to remote
        let originalSource = mockDataSource
        mockDataSource = .remote
        let result = fetchAllDigimons()
        mockDataSource = originalSource
        return result
    }
    
    // Reset all counters and test configuration
    func reset() {
        shouldReturnError = false
        shouldReturnEmpty = false
        mockDataFileName = "mockDigimon"
        mockDataSource = .cache
        mockImage = UIImage(systemName: "photo")
        loadDelay = 0
        
        fetchAllCallCount = 0
        fetchByLevelCallCount = 0
        fetchByNameCallCount = 0
        getImageCallCount = 0
        refreshDataCallCount = 0
        lastFetchedLevel = nil
        lastFetchedName = nil
        lastImageDigimon = nil
    }
} 
