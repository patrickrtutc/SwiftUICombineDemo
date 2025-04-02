//
//  APIProtocols.swift
//  DigimonAPISwiftUICombine
//
//  Created by Patrick Tung on 3/12/25.
//

import Foundation
import Combine

// MARK: - Network Request Protocol
/// Protocol for constructing URL requests
protocol NetworkRequestable {
    func createRequest(from urlComponents: URLComponents) -> URLRequest?
}

// MARK: - Network Response Protocol
/// Protocol for handling network responses
protocol NetworkResponseProcessable {
    func processResponse<T: Decodable>(data: Data, response: URLResponse) throws -> T
}

// MARK: - Network Session Protocol
/// Protocol for network session management
protocol NetworkSessionable {
    func dataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), Error>
}

// MARK: - API Service Protocol
/// Main API service protocol that combines request creation, execution, and response processing
protocol APIServiceable {
    func fetch<T: Decodable>(from urlComponents: URLComponents) -> AnyPublisher<T, Error>
}

// MARK: - Network Errors
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid"
        case .invalidResponse:
            return "The server response was invalid"
        case .httpError(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        case .decodingError:
            return "Failed to decode the response"
        case .unknown(let error):
            return "An unknown error occurred: \(error.localizedDescription)"
        }
    }
} 