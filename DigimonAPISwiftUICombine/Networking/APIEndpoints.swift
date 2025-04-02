//
//  ApiEndpoints.swift
//  DigimonAPISwiftUICombine
//
//  Created by Patrick Tung on 3/5/25.
//

import Foundation
import Combine

/// Contains all API endpoint configurations
struct APIEndpoints {
    // Base URLs
    private struct BaseURL {
        static let digimonAPI = "digimon-api.vercel.app"
    }
    
    // Path components
    private struct Path {
        static let api = "api"
        static let digimon = "digimon"
    }
    
    // Query parameters
    private struct QueryParams {
        static let name = "name"
        static let level = "level"
    }
    
    /// Endpoints for Digimon API
    struct Digimon {
        /// Returns all digimons
        static func getAllDigimons() -> URLComponents {
            var components = URLComponents()
            components.scheme = "https"
            components.host = BaseURL.digimonAPI
            components.path = "/\(Path.api)/\(Path.digimon)"
            return components
        }
        
        /// Returns digimons filtered by name
        static func getDigimonsByName(name: String) -> URLComponents {
            var components = getAllDigimons()
            components.queryItems = [
                URLQueryItem(name: QueryParams.name, value: name)
            ]
            return components
        }
        
        /// Returns digimons filtered by level
        static func getDigimonsByLevel(level: String) -> URLComponents {
            var components = getAllDigimons()
            components.queryItems = [
                URLQueryItem(name: QueryParams.level, value: level)
            ]
            return components
        }
    }
}

struct MockNetworkSession: NetworkSessionable {
    var mockResult: Result<(data: Data, response: URLResponse), Error>
    
    func dataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), Error> {
        return mockResult.publisher.eraseToAnyPublisher()
    }
}
