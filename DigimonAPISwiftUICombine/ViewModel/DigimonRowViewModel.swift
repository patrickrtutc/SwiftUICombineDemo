//
//  DigimonRowViewModel.swift
//  DigimonAPISwiftUICombine
//
//  Created by Patrick Tung on 3/14/25.
//

import Combine
import Foundation
import SwiftUI

// View model for DigimonRow that manages image loading
class DigimonRowViewModel: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadImage(for digimon: Digimon, using repository: DigimonRepository) {
        isLoading = true
        errorMessage = nil
        
        repository.getImage(for: digimon)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    print("Error loading image: \(error)")
                }
            }, receiveValue: { [weak self] image in
                self?.image = image
                self?.isLoading = false
            })
            .store(in: &cancellables)
    }
}
