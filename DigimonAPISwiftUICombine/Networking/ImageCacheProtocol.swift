//
//  ImageCacheProtocol.swift
//  DigimonAPISwiftUICombine
//
//  Created by Patrick Tung on 3/16/25.
//

import Foundation
import UIKit

/// Protocol defining operations for image caching
protocol ImageCacheable: Actor {
    /// Retrieves an image from cache or downloads it
    /// - Parameters:
    ///   - url: URL to fetch the image from
    ///   - digimonName: Optional name of the Digimon for CoreData lookup
    /// - Returns: UIImage for the requested URL
    /// - Throws: Error if image cannot be retrieved
    func image(from url: URL, digimonName: String?) async throws -> UIImage
    
    /// Clears all cached images
    func clearCache() async
}

// Make the existing ImageCache conform to the protocol
extension ImageCache: ImageCacheable {} 