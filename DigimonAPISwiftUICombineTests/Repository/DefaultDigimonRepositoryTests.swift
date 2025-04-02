//
//  DefaultDigimonRepositoryTests.swift
//  DigimonAPISwiftUICombineTests
//
//  Created by Patrick Tung on 3/16/25.
//

import XCTest
import Combine
import UIKit
@testable import DigimonAPISwiftUICombine

class DefaultDigimonRepositoryTests: XCTestCase {
    
    var repository: DefaultDigimonRepository!
    var mockAPIService: MockAPIService!
    var mockCoreDataManager: MockCoreDataManager!
    var mockImageCache: MockImageCache!
    var cancellables = Set<AnyCancellable>()
    
    // Sample data for testing
    let sampleDigimons = [
        Digimon(name: "Agumon", img: "https://example.com/agumon.jpg", level: "Rookie"),
        Digimon(name: "Gabumon", img: "https://example.com/gabumon.jpg", level: "Rookie")
    ]
    
    override func setUpWithError() throws {
        super.setUp()
        
        mockAPIService = MockAPIService()
        mockCoreDataManager = MockCoreDataManager()
        mockImageCache = MockImageCache()
        
        repository = DefaultDigimonRepository(
            apiService: mockAPIService,
            coreDataManager: mockCoreDataManager,
            imageCache: mockImageCache
        )
    }
    
    override func tearDownWithError() throws {
        repository = nil
        mockAPIService = nil
        mockCoreDataManager = nil
        mockImageCache = nil
        cancellables.removeAll()
        super.tearDown()
    }
    
    // MARK: - fetchAllDigimons Tests
    
    func testFetchAllDigimonsFromMemoryCache() {
        // Given
        let expectation = XCTestExpectation(description: "Fetch digimons from memory cache")
        
        // Setup repository with cached data using the testing methods
        repository.setTestCachedDigimons(sampleDigimons)
        repository.setTestLastFetchTimestamp(Date())
        
        // When
        var resultDigimons: [Digimon]?
        var resultError: Error?
        var resultDataSource: DataSource?
        
        repository.fetchAllDigimons()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { digimons in
                resultDigimons = digimons
            })
            .store(in: &cancellables)
        
        // Also test dataSourcePublisher
        repository.dataSourcePublisher
            .sink { dataSource in
                resultDataSource = dataSource
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertEqual(resultDigimons?.count, sampleDigimons.count)
        XCTAssertEqual(resultDataSource, .cache)
        
        // The API service shouldn't be called
        XCTAssertEqual(mockAPIService.fetchCallCount, 0)
        // Core data shouldn't be accessed
        XCTAssertEqual(mockCoreDataManager.fetchDigimonsCallCount, 0)
    }
    
    func testFetchAllDigimonsFromLocalStorage() {
        // Given
        let expectation = XCTestExpectation(description: "Fetch digimons from local storage")
        
        // Set up mock CoreData to return sample data
        mockCoreDataManager.mockDigimons = sampleDigimons
        
        // When
        var resultDigimons: [Digimon]?
        var resultError: Error?
        var resultDataSource: DataSource?
        
        repository.fetchAllDigimons()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { digimons in
                resultDigimons = digimons
            })
            .store(in: &cancellables)
        
        // Also test dataSourcePublisher
        repository.dataSourcePublisher
            .sink { dataSource in
                resultDataSource = dataSource
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertEqual(resultDigimons?.count, sampleDigimons.count)
        XCTAssertEqual(resultDataSource, .local)
        
        // Core data should be accessed
        XCTAssertEqual(mockCoreDataManager.fetchDigimonsCallCount, 1)
        
        // The API should be called in the background, but we don't wait for its completion
        // This is hard to test directly since it's in a background task
    }
    
    func testFetchAllDigimonsFromRemote() {
        // Given
        let expectation = XCTestExpectation(description: "Fetch digimons from remote API")
        
        // Set up mock CoreData to return empty array (to force API call)
        mockCoreDataManager.mockDigimons = []
        
        // Set up mock API to return sample data
        mockAPIService.mockResults = Result<[Digimon], Error>.success(sampleDigimons).publisher.eraseToAnyPublisher()
        
        // When
        var resultDigimons: [Digimon]?
        var resultError: Error?
        var resultDataSource: DataSource?
        
        repository.fetchAllDigimons()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { digimons in
                resultDigimons = digimons
            })
            .store(in: &cancellables)
        
        // Also test dataSourcePublisher
        repository.dataSourcePublisher
            .sink { dataSource in
                resultDataSource = dataSource
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertEqual(resultDigimons?.count, sampleDigimons.count)
        XCTAssertEqual(resultDataSource, .remote)
        
        // Core data should be accessed to check for local data
        XCTAssertEqual(mockCoreDataManager.fetchDigimonsCallCount, 1)
        
        // The API should be called
        XCTAssertEqual(mockAPIService.fetchCallCount, 1)
        
        // Core data should be updated with the fetched data
        XCTAssertEqual(mockCoreDataManager.savedDigimons.count, sampleDigimons.count)
    }
    
    func testFetchAllDigimonsAPIError() {
        // Given
        let expectation = XCTestExpectation(description: "Handle API error")
        let mockError = NSError(domain: "com.test", code: 404, userInfo: [NSLocalizedDescriptionKey: "Not found"])
        
        // Set up mock CoreData to return empty array (to force API call)
        mockCoreDataManager.mockDigimons = []
        
        // Set up mock API to return error
        mockAPIService.mockResults = Fail<[Digimon], Error>(error: mockError).eraseToAnyPublisher()
        
        // When
        var resultDigimons: [Digimon]?
        var resultError: Error?
        
        repository.fetchAllDigimons()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { digimons in
                resultDigimons = digimons
            })
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(resultError)
        XCTAssertNil(resultDigimons)
        
        // The error should be the one we set
        XCTAssertEqual((resultError as NSError?)?.domain, "com.test")
        XCTAssertEqual((resultError as NSError?)?.code, 404)
    }
    
    // MARK: - fetchDigimonsByName Tests
    
    func testFetchDigimonsByNameFromCache() {
        // Given
        let expectation = XCTestExpectation(description: "Fetch digimons by name from cache")
        let searchName = "agu" // Should match "Agumon"
        
        // Setup repository with cached data using testing methods
        repository.setTestCachedDigimons(sampleDigimons)
        
        // When
        var resultDigimons: [Digimon]?
        var resultError: Error?
        var resultDataSource: DataSource?
        
        repository.fetchDigimonsByName(searchName)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { digimons in
                resultDigimons = digimons
            })
            .store(in: &cancellables)
        
        // Also test dataSourcePublisher
        repository.dataSourcePublisher
            .sink { dataSource in
                resultDataSource = dataSource
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertEqual(resultDigimons?.count, 1)
        XCTAssertEqual(resultDigimons?.first?.name, "Agumon")
        XCTAssertEqual(resultDataSource, .cache)
        
        // The API service shouldn't be called
        XCTAssertEqual(mockAPIService.fetchCallCount, 0)
    }
    
    func testFetchDigimonsByNameFromRemote() {
        // Given
        let expectation = XCTestExpectation(description: "Fetch digimons by name from remote")
        let searchName = "agu" // Should match "Agumon"
        
        // Filter the sample data to match the search
        let filteredDigimons = sampleDigimons.filter { $0.name.lowercased().contains(searchName.lowercased()) }
        
        // We have no cached digimons (default nil)
        
        // Set up mock API to return filtered sample data
        mockAPIService.mockResults = Result<[Digimon], Error>.success(filteredDigimons).publisher.eraseToAnyPublisher()
        
        // When
        var resultDigimons: [Digimon]?
        var resultError: Error?
        var resultDataSource: DataSource?
        
        repository.fetchDigimonsByName(searchName)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { digimons in
                resultDigimons = digimons
            })
            .store(in: &cancellables)
        
        // Also test dataSourcePublisher
        repository.dataSourcePublisher
            .sink { dataSource in
                resultDataSource = dataSource
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertEqual(resultDigimons?.count, 1)
        XCTAssertEqual(resultDigimons?.first?.name, "Agumon")
        XCTAssertEqual(resultDataSource, .remote)
        
        // The API service should be called
        XCTAssertEqual(mockAPIService.fetchCallCount, 1)
    }
    
    // MARK: - fetchDigimonsByLevel Tests
    
    func testFetchDigimonsByLevel() {
        // Given
        let expectation = XCTestExpectation(description: "Fetch digimons by level")
        let searchLevel = "Rookie"
        
        // Filter the sample data to match the search
        let filteredDigimons = sampleDigimons.filter { $0.level == searchLevel }
        
        // Set up mock API to return filtered sample data
        mockAPIService.mockResults = Result<[Digimon], Error>.success(filteredDigimons).publisher.eraseToAnyPublisher()
        
        // When
        var resultDigimons: [Digimon]?
        var resultError: Error?
        var resultDataSource: DataSource?
        
        repository.fetchDigimonsByLevel(searchLevel)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { digimons in
                resultDigimons = digimons
            })
            .store(in: &cancellables)
        
        // Also test dataSourcePublisher
        repository.dataSourcePublisher
            .sink { dataSource in
                resultDataSource = dataSource
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertEqual(resultDigimons?.count, 2) // Both sample digimons are "Rookie"
        XCTAssertEqual(resultDataSource, .remote)
        
        // The API service should be called
        XCTAssertEqual(mockAPIService.fetchCallCount, 1)
    }
    
    // MARK: - getImage Tests
    
    func testGetImage() async throws {
        // Given
        let digimon = sampleDigimons[0]
        let testImage = UIImage(systemName: "star.fill")!
        
        // Configure mock image cache to return a test image
        if let imageURL = URL(string: digimon.img) {
            await mockImageCache.setMockImage(for: imageURL, name: digimon.name, image: testImage)
        }
        
        // When
        let expectation = XCTestExpectation(description: "Get image")
        var resultImage: UIImage?
        var resultError: Error?
        
        repository.getImage(for: digimon)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { image in
                resultImage = image
            })
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertNotNil(resultImage)
        
        // The image cache should be accessed
        let callCount = await mockImageCache.imageCallCount
        XCTAssertEqual(callCount, 1)
    }
    
    func testGetImageWithInvalidURL() {
        // Given
        let invalidURLDigimon = Digimon(name: "Invalid", img: "not a url", level: "Rookie")
        
        // When
        let expectation = XCTestExpectation(description: "Get image with invalid URL")
        var resultImage: UIImage?
        var resultError: Error?
        
        repository.getImage(for: invalidURLDigimon)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { image in
                resultImage = image
            })
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        
        // The image should either be nil OR a small placeholder depending on the implementation
        // Let's test the return value from the repository rather than making assumptions
        if let image = resultImage {
            // If an image is returned, verify it's a small placeholder
            XCTAssertEqual(image.size.width, 1)
            XCTAssertEqual(image.size.height, 1)
        }
    }
    
    // MARK: - refreshData Tests
    
    func testRefreshData() {
        // Given
        let expectation = XCTestExpectation(description: "Refresh data")
        
        // Set up cached data first using testing methods
        repository.setTestCachedDigimons(sampleDigimons)
        repository.setTestLastFetchTimestamp(Date())
        
        // Set up mock API to return sample data
        mockAPIService.mockResults = Result<[Digimon], Error>.success(sampleDigimons).publisher.eraseToAnyPublisher()
        
        // When
        var resultDigimons: [Digimon]?
        var resultError: Error?
        var resultDataSource: DataSource?
        
        repository.refreshData()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { digimons in
                resultDigimons = digimons
            })
            .store(in: &cancellables)
        
        // Also test dataSourcePublisher
        repository.dataSourcePublisher
            .sink { dataSource in
                resultDataSource = dataSource
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertEqual(resultDigimons?.count, sampleDigimons.count)
        XCTAssertEqual(resultDataSource, .remote)
        
        // Check that it did not use the cache
        // The API service should be called
        XCTAssertEqual(mockAPIService.fetchCallCount, 1)
        
        // Core data should be updated with the fetched data
        XCTAssertEqual(mockCoreDataManager.savedDigimons.count, sampleDigimons.count)
    }
    
    // MARK: - Helper Methods
    
    // No helper methods needed now
}

// MARK: - Mock Implementations

// Mock API Service
class MockAPIService: APIServiceable {
    var fetchCallCount = 0
    var mockResults = Empty<[Digimon], Error>().eraseToAnyPublisher()
    
    func fetch<T>(from components: URLComponents) -> AnyPublisher<T, Error> where T: Decodable {
        fetchCallCount += 1
        return mockResults as! AnyPublisher<T, Error>
    }
}

// We already have MockCoreDataManager from previous code 
