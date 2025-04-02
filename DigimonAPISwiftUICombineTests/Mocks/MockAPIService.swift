//
//  MockAPIService.swift
//  DigimonAPISwiftUICombineTests
//
//  Created by Patrick Tung on 3/4/25.
//

import Combine
import Foundation

/// Mock implementation of APIServiceable for testing
class MockAPIService: APIServiceable {
    // Test configuration
    var shouldReturnError = false
    var testPath: String = ""
    var delay: TimeInterval = 0
    
    // Monitoring
    var fetchCallCount = 0
    var lastComponents: URLComponents?
    
    func fetch<T>(from urlComponents: URLComponents) -> AnyPublisher<T, Error> where T: Decodable {
        fetchCallCount += 1
        lastComponents = urlComponents
        
        // Simulate an error if requested
        if shouldReturnError {
            return Fail(error: NetworkError.httpError(statusCode: 500))
                .delay(for: .seconds(delay), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        let bundle = Bundle(for: MockAPIService.self)
        guard let path = bundle.url(forResource: testPath, withExtension: "json") else {
            print("Error: Could not find \(testPath).json in test bundle")
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        do {
            // Load and decode the JSON data
            let data = try Data(contentsOf: path)
            let parsedData = try JSONDecoder().decode(T.self, from: data)
            return Just(parsedData)
                .setFailureType(to: Error.self)
                .delay(for: .seconds(delay), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        } catch {
            print("Error decoding data from \(testPath).json: \(error)")
            return Fail(error: NetworkError.decodingError(error))
                .eraseToAnyPublisher()
        }
    }
    
    // Reset test state
    func reset() {
        shouldReturnError = false
        testPath = ""
        delay = 0
        fetchCallCount = 0
        lastComponents = nil
    }
}
