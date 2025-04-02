//
//  ViewState.swift
//  DigimonAPISwiftUICombine
//
//  Created by Patrick Tung on 3/5/25.
//

import Foundation

enum ViewState: Equatable {
    case idle
    case loading
    case loaded([Digimon])
    case error(Error)
    
    func getDigimon() -> [Digimon]? {
        switch self {
        case .loaded(let digimon):
            return digimon
        default:
            return nil
        }
    }
    
    // MARK: - Equatable implementation
    
    static func == (lhs: ViewState, rhs: ViewState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case (.loaded(let lhsDigimons), .loaded(let rhsDigimons)):
            // Compare arrays by their count and elements (assuming Digimon is Equatable)
            return lhsDigimons.count == rhsDigimons.count && 
                   zip(lhsDigimons, rhsDigimons).allSatisfy { $0.name == $1.name && $0.level == $1.level }
        case (.error(let lhsError), .error(let rhsError)):
            // For errors, compare the localized descriptions
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
