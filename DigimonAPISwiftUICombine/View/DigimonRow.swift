//
//  DigimonRow.swift
//  DigimonAPISwiftUICombine
//
//  Created by Patrick Tung on 3/4/25.
//

import SwiftUI
import Combine

struct DigimonRow: View {
    let digimon: Digimon
    @EnvironmentObject private var mainViewModel: SearchableDigimonListView.ViewModel
    @Environment(\.horizontalSizeClass) var sizeClass
    
    // Use StateObject to maintain the view model's lifecycle
    @StateObject private var viewModel = DigimonRowViewModel()
    
    var body: some View {
        HStack {
            ZStack {
                if let image = viewModel.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else if viewModel.isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .opacity(0.3)
                }
            }
            .frame(width: sizeClass == .compact ? 150 : 200,
                   height: sizeClass == .compact ? 150 : 200)
            
            VStack(alignment: .leading) {
                Text(digimon.name)
                    .font(.headline)
                
                Text(digimon.level)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Show data source indicator if available
                if let dataSource = mainViewModel.dataSource {
                    Text("Source: \(dataSource.description)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .onAppear {
            viewModel.loadImage(for: digimon, using: mainViewModel.repository)
        }
    }
}

#Preview {
    DigimonRow(digimon: Digimon(name: "Koromon", img: "https://digimon.shadowsmith.com/img/koromon.jpg", level: "In Training"))
        .environmentObject(SearchableDigimonListView.ViewModel())
        .frame(width: 250, height: 100, alignment: .center)
}
