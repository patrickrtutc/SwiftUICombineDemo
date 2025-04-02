//
//  DefaultDigimonRepository.swift
//  DigimonAPISwiftUICombine
//
//  Created by Patrick Tung on 3/12/25.
//

import Foundation
import Combine
import UIKit

/// Default implementation of DigimonRepository that coordinates between remote API and local storage
class DefaultDigimonRepository: DigimonRepository {
    // Dependencies
    private let apiService: APIServiceable
    private let coreDataManager: CoreDataManagerProtocol
    private let imageCache: ImageCacheable
    
    // Memory cache for optimizing frequent requests
    private var cachedDigimons: [Digimon]?
    private var lastFetchTimestamp: Date?
    private let cacheDuration: TimeInterval = 300 // 5 minutes cache freshness
    
    // Subject for tracking data source - useful for analytics or UI indicators
    private let dataSourceSubject = CurrentValueSubject<DataSource?, Never>(nil)
    var dataSourcePublisher: AnyPublisher<DataSource?, Never> {
        return dataSourceSubject.eraseToAnyPublisher()
    }
    
    /// Initializes repository with the given dependencies
    /// - Parameters:
    ///   - apiService: Service for API requests
    ///   - coreDataManager: Manager for local persistence
    ///   - imageCache: Cache for images
    init(
        apiService: APIServiceable = APIService(),
        coreDataManager: CoreDataManagerProtocol = CoreDataManager.shared,
        imageCache: ImageCacheable = ImageCache.shared
    ) {
        self.apiService = apiService
        self.coreDataManager = coreDataManager
        self.imageCache = imageCache
    }
    
    /// Fetches all Digimons with a smart caching strategy
    /// - Returns: Publisher with Digimon array or error
    func fetchAllDigimons() -> AnyPublisher<[Digimon], Error> {
        // Check in-memory cache first (fastest)
        if let cachedDigimons = cachedDigimons, 
           let timestamp = lastFetchTimestamp,
           Date().timeIntervalSince(timestamp) < cacheDuration {
            dataSourceSubject.send(.cache)
            return Just(cachedDigimons)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Then check Core Data (still fast, but requires disk access)
        let localData = coreDataManager.fetchDigimons()
        if !localData.isEmpty {
            // Update memory cache
            self.cachedDigimons = localData
            self.lastFetchTimestamp = Date()
            
            dataSourceSubject.send(.local)
            
            // Return the data from Core Data and also refresh in background for next time
            refreshInBackground()
            
            return Just(localData)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // If nothing local, fetch from API and save
        dataSourceSubject.send(.remote)
        
        let urlComponents = APIEndpoints.Digimon.getAllDigimons()
        
        return apiService.fetch(from: urlComponents)
            .handleEvents(receiveOutput: { [weak self] (digimons: [Digimon]) in
                // Update both caches
                self?.coreDataManager.saveDigimons(digimons)
                self?.cachedDigimons = digimons
                self?.lastFetchTimestamp = Date()
            })
            .eraseToAnyPublisher()
    }
    
    /// Fetches Digimons filtered by level
    func fetchDigimonsByLevel(_ level: String) -> AnyPublisher<[Digimon], Error> {
        dataSourceSubject.send(.remote) // This is likely always from remote
        
        let urlComponents = APIEndpoints.Digimon.getDigimonsByLevel(level: level)
        
        return apiService.fetch(from: urlComponents)
            .eraseToAnyPublisher()
    }
    
    /// Fetches Digimons filtered by name
    func fetchDigimonsByName(_ name: String) -> AnyPublisher<[Digimon], Error> {
        // First try to filter from cache/local if we have it
        if let cachedDigimons = self.cachedDigimons {
            let filtered = cachedDigimons.filter {
                $0.name.lowercased().contains(name.lowercased())
            }
            
            if !filtered.isEmpty {
                dataSourceSubject.send(.cache)
                return Just(filtered)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
        }
        
        // Otherwise search via API
        dataSourceSubject.send(.remote)
        let urlComponents = APIEndpoints.Digimon.getDigimonsByName(name: name)
        
        return apiService.fetch(from: urlComponents)
            .eraseToAnyPublisher()
    }
    
    /// Gets a cached image for a Digimon
    func getImage(for digimon: Digimon) -> AnyPublisher<UIImage?, Error> {
        // Create a Deferred publisher that will execute the image loading asynchronously
        return Deferred {
            Future<UIImage?, Error> { [weak self] promise in
                guard let self = self else {
                    promise(.failure(NSError(domain: "Repository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository has been deallocated"])))
                    return
                }
                
                Task {
                    do {
                        // We need a non-optional URL for the image cache actor
                        guard let imageUrl = URL(string: digimon.img) else {
                            promise(.success(nil))
                            return
                        }
                        
                        // Try to get the image from the cache
                        let image = try await self.imageCache.image(from: imageUrl, digimonName: digimon.name)
                        promise(.success(image))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// Invalidates all caches and forces a refresh from remote sources
    func refreshData() -> AnyPublisher<[Digimon], Error> {
        // Clear memory cache
        cachedDigimons = nil
        lastFetchTimestamp = nil
        
        dataSourceSubject.send(.remote)
        
        // Fetch fresh data from API
        let urlComponents = APIEndpoints.Digimon.getAllDigimons()
        
        return apiService.fetch(from: urlComponents)
            .handleEvents(receiveOutput: { [weak self] (digimons: [Digimon]) in
                // Update caches
                self?.coreDataManager.saveDigimons(digimons)
                self?.cachedDigimons = digimons
                self?.lastFetchTimestamp = Date()
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private methods
    
    /// Refreshes data in background without blocking UI
    private func refreshInBackground() {
        let urlComponents = APIEndpoints.Digimon.getAllDigimons()
        
        // Perform the fetch but don't wait for completion
        // This will update our caches for the next time
        apiService.fetch(from: urlComponents)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Background refresh failed: \(error)")
                }
            }, receiveValue: { [weak self] (digimons: [Digimon]) in
                self?.coreDataManager.saveDigimons(digimons)
                self?.cachedDigimons = digimons
                self?.lastFetchTimestamp = Date()
            })
            .store(in: &cancellables)
    }
    
    // Storage for active publishers
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Testing Extensions
extension DefaultDigimonRepository {
    /// Sets cached Digimons for testing purposes only
    func setTestCachedDigimons(_ digimons: [Digimon]) {
        self.cachedDigimons = digimons
    }
    
    /// Sets last fetch timestamp for testing purposes only
    func setTestLastFetchTimestamp(_ date: Date) {
        self.lastFetchTimestamp = date
    }
    
    /// Clears all cached data for testing purposes only
    func clearTestCache() {
        self.cachedDigimons = nil
        self.lastFetchTimestamp = nil
    }
} 
