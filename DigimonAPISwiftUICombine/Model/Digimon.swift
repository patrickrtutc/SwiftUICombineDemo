//
//  Digimon.swift
//  DigimonAPISwiftUICombine
//
//  Created by Patrick Tung on 3/4/25.
//

import Foundation

struct Digimon: Decodable, Equatable {
    let name: String
    let img: String
    let level: String
    
    // MARK: - Equatable conformance
    
    static func == (lhs: Digimon, rhs: Digimon) -> Bool {
        return lhs.name == rhs.name &&
               lhs.img == rhs.img &&
               lhs.level == rhs.level
    }
}
