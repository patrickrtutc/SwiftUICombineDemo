//
//  DigimonViewModelTests.swift
//  DigimonAPISwiftUICombineTests
//
//  Created by Patrick Tung on 3/14/25.
//

import XCTest
import Combine
@testable import DigimonAPISwiftUICombine

class DigimonViewModelTests: XCTestCase {
    var viewModel: SearchableDigimonListView.ViewModel!
    var mockRepository: MockDigimonRepository!
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        mockRepository = MockDigimonRepository()
        viewModel = SearchableDigimonListView.ViewModel(repository: mockRepository)
    }
    
    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        cancellables.removeAll()
        super.tearDown()
    }
    
    // MARK: - Test fetchDigimons
    
    func testFetchDigimonsSuccess() {
        // Arrange
        let expectation = expectation(description: "Fetch digimons succeeds")
        var stateUpdates: [ViewState] = []
        
        // Act
        viewModel.$state
            .sink { state in
                stateUpdates.append(state)
                
                if case .loaded(let digimons) = state, !digimons.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.fetchDigimons()
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(mockRepository.fetchAllCallCount, 1, "Repository's fetchAll should be called exactly once")
        XCTAssertEqual(stateUpdates.count, 3, "State should update three times: initial, loading, and loaded")
        XCTAssertEqual(stateUpdates[0], .idle, "Initial state should be idle")
        XCTAssertEqual(stateUpdates[1], .loading, "Second state should be loading")
        
        if case .loaded(let digimons) = stateUpdates[2] {
            XCTAssertFalse(digimons.isEmpty, "Digimons array should not be empty")
        } else {
            XCTFail("Final state should be .loaded")
        }
    }
    
    func testFetchDigimonsError() {
        // Arrange
        mockRepository.shouldReturnError = true
        let expectation = expectation(description: "Fetch digimons fails")
        var stateUpdates: [ViewState] = []
        
        // Act
        viewModel.$state
            .sink { state in
                stateUpdates.append(state)
                
                if case .error = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.fetchDigimons()
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(mockRepository.fetchAllCallCount, 1, "Repository's fetchAll should be called exactly once")
        XCTAssertEqual(stateUpdates.count, 3, "State should update three times: initial, loading, and error")
        XCTAssertEqual(stateUpdates[0], .idle, "Initial state should be idle")
        XCTAssertEqual(stateUpdates[1], .loading, "Second state should be loading")
        
        if case .error = stateUpdates[2] {
            // Success
        } else {
            XCTFail("Final state should be .error")
        }
    }
    
    func testFetchDigimonsEmptyResult() {
        // Arrange
        mockRepository.shouldReturnEmpty = true
        let expectation = expectation(description: "Fetch digimons returns empty array")
        var stateUpdates: [ViewState] = []
        
        // Act
        viewModel.$state
            .sink { state in
                stateUpdates.append(state)
                
                if case .loaded(let digimons) = state {
                    XCTAssertTrue(digimons.isEmpty)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.fetchDigimons()
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(mockRepository.fetchAllCallCount, 1, "Repository's fetchAll should be called exactly once")
        XCTAssertEqual(stateUpdates.count, 3, "State should update three times: initial, loading, and loaded")
        XCTAssertEqual(stateUpdates[0], .idle, "Initial state should be idle")
        XCTAssertEqual(stateUpdates[1], .loading, "Second state should be loading")
        
        if case .loaded(let digimons) = stateUpdates[2] {
            XCTAssertTrue(digimons.isEmpty, "Digimons array should be empty")
        } else {
            XCTFail("Final state should be .loaded")
        }
    }
    
    // MARK: - Test fetchDigimonsByLevel
    
    func testFetchDigimonsByLevelSuccess() {
        // Arrange
        let level = "Champion"
        let expectation = expectation(description: "Fetch digimons by level succeeds")
        
        // Act
        viewModel.fetchDigimonsByLevel(level)
        
        // Wait briefly for async operations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Assert
            XCTAssertEqual(self.mockRepository.fetchByLevelCallCount, 1)
            XCTAssertEqual(self.mockRepository.lastFetchedLevel, level)
            
            if case .loaded(let digimons) = self.viewModel.state {
                XCTAssertFalse(digimons.isEmpty)
                XCTAssertTrue(digimons.allSatisfy { $0.level == level })
            } else {
                XCTFail("Expected .loaded state")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test fetchDigimonsByName
    
    func testFetchDigimonsByNameSuccess() {
        // Arrange
        let name = "Agumon"
        let expectation = expectation(description: "Fetch digimons by name succeeds")
        
        // Act
        viewModel.fetchDigimonsByName(name)
        
        // Wait briefly for async operations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Assert
            XCTAssertEqual(self.mockRepository.fetchByNameCallCount, 1)
            XCTAssertEqual(self.mockRepository.lastFetchedName, name)
            
            if case .loaded(let digimons) = self.viewModel.state {
                XCTAssertFalse(digimons.isEmpty)
                XCTAssertTrue(digimons.allSatisfy { $0.name.lowercased().contains(name.lowercased()) })
            } else {
                XCTFail("Expected .loaded state")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test refreshData
    
    func testRefreshDataSuccess() {
        // Arrange
        let expectation = expectation(description: "Refresh data succeeds")
        
        // Act
        viewModel.refreshData()
        
        // Wait briefly for async operations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Assert
            XCTAssertEqual(self.mockRepository.refreshDataCallCount, 1)
            
            if case .loaded(let digimons) = self.viewModel.state {
                XCTAssertFalse(digimons.isEmpty)
            } else {
                XCTFail("Expected .loaded state")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test DataSource Updates
    
    func testDataSourceUpdates() {
        // Arrange
        let source: DataSource = .remote
        let expectation = expectation(description: "Data source updates")
        
        // Act
        viewModel.$dataSource
            .dropFirst() // Skip initial nil value
            .sink { dataSource in
                if dataSource == source {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        mockRepository.dataSourceSubject.send(source)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.dataSource, source)
    }
    
    // MARK: - Test getImage
    
    func testGetImageSuccess() {
        // Arrange
        let mockImage = UIImage(systemName: "photo")
        mockRepository.mockImage = mockImage
        let digimon = Digimon(name: "TestDigimon", img: "https://example.com/test.jpg", level: "Test")
        let expectation = expectation(description: "Get image succeeds")
        var receivedImage: UIImage?
        
        // Act
        viewModel.getImage(for: digimon)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("Should not fail")
                }
            }, receiveValue: { image in
                receivedImage = image
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.getImageCallCount, 1)
        XCTAssertEqual(mockRepository.lastImageDigimon?.name, digimon.name)
        XCTAssertNotNil(receivedImage)
    }
    
    // MARK: - Test filteredDigimons
    
    func testFilteredDigimonsWithEmptySearchText() {
        // Arrange
        let digimons = [
            Digimon(name: "Agumon", img: "url1", level: "Champion"),
            Digimon(name: "Gabumon", img: "url2", level: "Champion")
        ]
        viewModel.state = .loaded(digimons)
        viewModel.searchText = ""
        
        // Act & Assert
        XCTAssertEqual(viewModel.filteredDigimons.count, 2)
    }
    
    func testFilteredDigimonsWithSearchText() {
        // Arrange
        let digimons = [
            Digimon(name: "Agumon", img: "url1", level: "Champion"),
            Digimon(name: "Gabumon", img: "url2", level: "Champion")
        ]
        viewModel.state = .loaded(digimons)
        viewModel.searchText = "agu"
        
        // Act & Assert
        XCTAssertEqual(viewModel.filteredDigimons.count, 1)
        XCTAssertEqual(viewModel.filteredDigimons.first?.name, "Agumon")
    }
} 
