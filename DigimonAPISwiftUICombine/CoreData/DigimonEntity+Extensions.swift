//
//  DigimonEntity+Extensions.swift
//  DigimonAPISwiftUICombine
//
//  Created by Patrick Tung on 3/12/25.
//

import Foundation
import UIKit
import CoreData

// Extension to DigimonEntity for image handling
extension DigimonEntity {
    // Separate file cache for images since they can be large
    private static let imageFileManager = FileManager.default
    private static let imageCacheDirectory: URL? = {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        return cachesDirectory?.appendingPathComponent("digimon_images", isDirectory: true)
    }()
    
    // Create the cache directory if it doesn't exist
    static func setupImageCache() {
        guard let imageCacheDirectory = imageCacheDirectory else { return }
        
        if !imageFileManager.fileExists(atPath: imageCacheDirectory.path) {
            do {
                try imageFileManager.createDirectory(at: imageCacheDirectory, withIntermediateDirectories: true)
            } catch {
                print("Failed to create image cache directory: \(error)")
            }
        }
    }
    
    // Get the URL for an image with the given ID
    private static func imageURL(for id: String) -> URL? {
        return imageCacheDirectory?.appendingPathComponent(id)
    }
    
    // Save image to disk
    func saveImage(_ image: UIImage) {
        guard let name = self.name, !name.isEmpty,
              let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        // Create a unique identifier for the image based on the digimon name
        let imageId = name.replacingOccurrences(of: " ", with: "_").lowercased()
        
        Self.setupImageCache()
        
        if let imageURL = Self.imageURL(for: imageId) {
            do {
                try imageData.write(to: imageURL)
                print("Saved image for \(name) at \(imageURL)")
            } catch {
                print("Failed to save image for \(name): \(error)")
            }
        }
    }
    
    // Load image from disk
    func loadImage() -> UIImage? {
        guard let name = self.name, !name.isEmpty else { return nil }
        
        // Create the same unique identifier used when saving
        let imageId = name.replacingOccurrences(of: " ", with: "_").lowercased()
        
        guard let imageURL = Self.imageURL(for: imageId),
              Self.imageFileManager.fileExists(atPath: imageURL.path) else {
            return nil
        }
        
        do {
            let imageData = try Data(contentsOf: imageURL)
            return UIImage(data: imageData)
        } catch {
            print("Failed to load image for \(name): \(error)")
            return nil
        }
    }
    
    // Delete image from disk
    func deleteImage() {
        guard let name = self.name, !name.isEmpty else { return }
        
        let imageId = name.replacingOccurrences(of: " ", with: "_").lowercased()
        
        if let imageURL = Self.imageURL(for: imageId),
           Self.imageFileManager.fileExists(atPath: imageURL.path) {
            do {
                try Self.imageFileManager.removeItem(at: imageURL)
            } catch {
                print("Failed to delete image for \(name): \(error)")
            }
        }
    }
} 