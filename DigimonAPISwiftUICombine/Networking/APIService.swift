//
//  ApiService.swift
//  DigimonAPISwiftUICombine
//
//  Created by Patrick Tung on 3/5/25.
//

import Foundation
import Combine

// MARK: - Default implementations

/// Default implementation of NetworkRequestable
struct DefaultNetworkRequestBuilder: NetworkRequestable {
    func createRequest(from urlComponents: URLComponents) -> URLRequest? {
        guard let url = urlComponents.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}

/// Default implementation of NetworkResponseProcessable
struct DefaultNetworkResponseProcessor: NetworkResponseProcessable {
    func processResponse<T: Decodable>(data: Data, response: URLResponse) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}

/// URL Session adapter conforming to NetworkSessionable
struct URLSessionAdapter: NetworkSessionable {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func dataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), Error> {
        return session.dataTaskPublisher(for: request)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
}

// MARK: - API Service Implementation
/// Concrete implementation of APIServiceable
struct APIService: APIServiceable {
    private let requestBuilder: NetworkRequestable
    private let networkSession: NetworkSessionable
    private let responseProcessor: NetworkResponseProcessable
    
    init(
        requestBuilder: NetworkRequestable = DefaultNetworkRequestBuilder(),
        networkSession: NetworkSessionable = URLSessionAdapter(),
        responseProcessor: NetworkResponseProcessable = DefaultNetworkResponseProcessor()
    ) {
        self.requestBuilder = requestBuilder
        self.networkSession = networkSession
        self.responseProcessor = responseProcessor
    }
    
    func fetch<T: Decodable>(from urlComponents: URLComponents) -> AnyPublisher<T, Error> {
        guard let request = requestBuilder.createRequest(from: urlComponents) else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        return networkSession.dataTaskPublisher(for: request)
            .tryMap { [responseProcessor] data, response in
                try responseProcessor.processResponse(data: data, response: response) as T
            }
            .mapError { error in
                if let networkError = error as? NetworkError {
                    return networkError
                }
                return NetworkError.unknown(error)
            }
            .eraseToAnyPublisher()
    }
} 