//
//  DigimonRepository.swift
//  DigimonAPISwiftUICombine
//
//  Created by Patrick Tung on 3/12/25.
//

import Foundation
import Combine
import UIKit

/// Protocol defining operations for accessing Digimon data
protocol DigimonRepository {
    /// Fetches all Digimons, potentially from multiple sources
    func fetchAllDigimons() -> AnyPublisher<[Digimon], Error>
    
    /// Fetches Digimons filtered by level
    func fetchDigimonsByLevel(_ level: String) -> AnyPublisher<[Digimon], Error>
    
    /// Fetches Digimons filtered by name
    func fetchDigimonsByName(_ name: String) -> AnyPublisher<[Digimon], Error>
    
    /// Gets a cached image for a Digimon
    func getImage(for digimon: Digimon) -> AnyPublisher<UIImage?, Error>
    
    /// Invalidates all caches and forces a refresh from remote sources
    func refreshData() -> AnyPublisher<[Digimon], Error>
    
    /// Publisher that emits the current data source when it changes
    var dataSourcePublisher: AnyPublisher<DataSource?, Never> { get }
}

/// Enum representing the different data sources
enum DataSource {
    case remote
    case local
    case cache
    
    var description: String {
        switch self {
        case .remote: return "Remote API"
        case .local: return "Local Database"
        case .cache: return "Memory Cache"
        }
    }
}

/// Result wrapper that includes the source of the data
struct RepositoryResult<T> {
    let data: T
    let source: DataSource
} 