//
//  CoreDataManagerProtocol.swift
//  DigimonAPISwiftUICombine
//
//  Created by Patrick Tung on 3/16/25.
//

import Foundation
import UIKit
import CoreData

/// Protocol defining operations for CoreData persistence layer
protocol CoreDataManagerProtocol {
    /// Persistent container for the CoreData stack
    var container: NSPersistentContainer { get }
    
    /// Saves digimon data to CoreData
    /// - Parameter digimons: Array of Digimon models to save
    func saveDigimons(_ digimons: [Digimon])
    
    /// Fetches all Digimon entities from CoreData
    /// - Returns: Array of Digimon models
    func fetchDigimons() -> [Digimon]
    
    /// Retrieves cached image for a specific Digimon
    /// - Parameter digimonName: Name of the Digimon to get image for
    /// - Returns: Optional UIImage if found in cache
    func getCachedImage(for digimonName: String) -> UIImage?
    
    /// Clears all stored data including images
    func clearAllData()
}

// Make the existing CoreDataManager conform to the protocol
extension CoreDataManager: CoreDataManagerProtocol {}
