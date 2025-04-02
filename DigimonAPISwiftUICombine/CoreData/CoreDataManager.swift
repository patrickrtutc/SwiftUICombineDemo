//
//  CoreDataManager.swift
//  DigimonAPISwiftUICombine
//
//  Created by Patrick Tung on 3/10/25.
//

import CoreData
import UIKit
import Combine

class CoreDataManager {
    static let shared = CoreDataManager()
    let container: NSPersistentContainer
    
    private init() {
        container = NSPersistentContainer(name: "DigimonAPISwiftUICombine") // Make sure this matches your .xcdatamodeld file name
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data failed to load: \(error)")
            }
        }
        
        // Setup image cache directory
        DigimonEntity.setupImageCache()
    }
    
    // Save digimon data with deferred image download
    func saveDigimons(_ digimons: [Digimon]) {
        let context = container.viewContext
        context.perform {
            // Get existing entities before deletion for image cleanup
            let fetchRequest: NSFetchRequest<DigimonEntity> = DigimonEntity.fetchRequest()
            if let existingEntities = try? context.fetch(fetchRequest) {
                // Delete associated images
                for entity in existingEntities {
                    entity.deleteImage()
                }
            }
            
            // Clear existing data
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: DigimonEntity.fetchRequest() as! NSFetchRequest<NSFetchRequestResult>)
            _ = try? context.execute(batchDeleteRequest)
            
            // Save new data
            for digimon in digimons {
                let entity = DigimonEntity(context: context)
                entity.name = digimon.name
                entity.img = digimon.img
                entity.level = digimon.level
                
                // Download and cache image in background
                if let imageUrl = URL(string: digimon.img) {
                    self.downloadAndCacheImage(for: entity, from: imageUrl)
                }
            }
            
            try? context.save()
        }
    }
    
    // Download and cache an image for a digimon entity
    private func downloadAndCacheImage(for entity: DigimonEntity, from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  let image = UIImage(data: data),
                  error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Failed to download image from \(url): \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Save the image in the filesystem cache
            entity.saveImage(image)
        }.resume()
    }
    
    func fetchDigimons() -> [Digimon] {
        let context = container.viewContext
        let request = DigimonEntity.fetchRequest()
        
        guard let entities = try? context.fetch(request) else { return [] }
        return entities.map { Digimon(name: $0.name ?? "", img: $0.img ?? "", level: $0.level ?? "") }
    }
    
    // Get a cached image for a digimon if available
    func getCachedImage(for digimonName: String) -> UIImage? {
        let context = container.viewContext
        let request = DigimonEntity.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", digimonName)
        request.fetchLimit = 1
        
        guard let entity = try? context.fetch(request).first else { return nil }
        return entity.loadImage()
    }
    
    // Clear all data including images
    func clearAllData() {
        let context = container.viewContext
        
        // Get all entities for image deletion
        let fetchRequest: NSFetchRequest<DigimonEntity> = DigimonEntity.fetchRequest()
        if let entities = try? context.fetch(fetchRequest) {
            for entity in entities {
                entity.deleteImage()
            }
        }
        
        // Delete all entities
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: DigimonEntity.fetchRequest() as! NSFetchRequest<NSFetchRequestResult>)
        _ = try? context.execute(batchDeleteRequest)
        
        try? context.save()
    }
}
