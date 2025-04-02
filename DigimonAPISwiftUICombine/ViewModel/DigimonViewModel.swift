//
//  DigimonViewModel.swift
//  DigimonAPISwiftUICombine
//
//  Created by Patrick Tung on 3/4/25.
//

import SwiftUI
import Combine

extension SearchableDigimonListView {
    
    class ViewModel: ObservableObject {
        // UI state
        @Published var searchText: String = ""
        @Published var state: ViewState = .idle
        @Published var dataSource: DataSource?
        
        // Dependencies - make repository public for views that need direct access
        let repository: DigimonRepository
        private var cancellables = Set<AnyCancellable>()
        
        init(repository: DigimonRepository = DefaultDigimonRepository()) {
            self.repository = repository
            
            // Subscribe to data source updates from the repository
            repository.dataSourcePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] source in
                    self?.dataSource = source
                }
                .store(in: &cancellables)
        }
        
        var filteredDigimons: [Digimon] {
            guard let digimons = state.getDigimon() else { return [] }
            return searchText.isEmpty ? digimons : digimons.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        func fetchDigimons() {
            state = .loading
            
            repository.fetchAllDigimons()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        self?.state = .error(error)
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] digimons in
                    self?.state = .loaded(digimons)
                })
                .store(in: &cancellables)
        }
        
        // Fetch digimons by level
        func fetchDigimonsByLevel(_ level: String) {
            state = .loading
            
            repository.fetchDigimonsByLevel(level)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        self?.state = .error(error)
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] digimons in
                    self?.state = .loaded(digimons)
                })
                .store(in: &cancellables)
        }
        
        // Fetch digimons by name
        func fetchDigimonsByName(_ name: String) {
            state = .loading
            
            repository.fetchDigimonsByName(name)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        self?.state = .error(error)
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] digimons in
                    self?.state = .loaded(digimons)
                })
                .store(in: &cancellables)
        }
        
        // Force refresh data
        func refreshData() {
            state = .loading
            
            repository.refreshData()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        self?.state = .error(error)
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] digimons in
                    self?.state = .loaded(digimons)
                })
                .store(in: &cancellables)
        }
        
        // Get image for a digimon
        func getImage(for digimon: Digimon) -> AnyPublisher<UIImage?, Error> {
            return repository.getImage(for: digimon)
        }
    }
}
