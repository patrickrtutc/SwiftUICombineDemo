//
//  ContentView.swift
//  DigimonAPISwiftUICombine
//
//  Created by Patrick Tung on 3/4/25.
//

import SwiftUI
import FirebaseAnalytics

struct SearchableDigimonListView: View {
    
    @EnvironmentObject private var viewModel: ViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                switch viewModel.state {
                case .idle:
                    Color.clear.onAppear { viewModel.fetchDigimons() }
                case .loading:
                    ProgressView("Loading Digimons...")
                case .loaded:
                    Button("Crash") {
                      fatalError("Crash was triggered")
                    }
                    List(viewModel.filteredDigimons, id: \.name) { digimon in
                        HStack {
                            DigimonRow(digimon: digimon)
                        }
                    }
                case .error(let message):
                    VStack {
                        Text("Error: \(message)").foregroundColor(.red)
                        Button("Retry") {
                            Analytics
                                .logEvent(
                                    AnalyticsEventSelectContent,
                                    parameters: [
                                        AnalyticsParameterItemID:"Retry",
                                        AnalyticsParameterItemName:"Retry Button",
                                        AnalyticsParameterContentType: "Retry Button"]
                                )
                            viewModel.fetchDigimons()
                        }
                    }
                }
            }
            .navigationTitle("Digimon List")
            .searchable(text: $viewModel.searchText, prompt: "Search")
            .onAppear {
                Analytics
                    .logEvent(
                        AnalyticsEventScreenView,
                        parameters: [AnalyticsEventScreenView:"SearchableDigimonListView"]
                    )
                viewModel.fetchDigimons()
            }
            .refreshable {
                viewModel.fetchDigimons()
            }
        }
    }
}
