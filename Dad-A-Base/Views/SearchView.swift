//
//  SearchView.swift
//  Dad-A-Base
//
//  Created by Andrew Pitblado on 2026-03-13.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = JokeSearchViewModel()
    
    private let categories: [JokeCategory] = [
        .init(name: "Animals", term:"dog"),
        .init(name: "Food", term:"food"),
        .init(name: "Puns", term:"pun"),
        .init(name: "School", term:"school"),
        .init(name: "Tech", term: "computer")
    ]
    
    
    var body: some View {
        NavigationStack{
            ZStack {
                Color.red
                    .ignoresSafeArea()
                VStack (spacing: 12){
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories) { category in
                                Button(category.name) {
                                    viewModel.searchTerm = category.term
                                    Task {                                    await viewModel.search()}
                                }.padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Capsule())
                            }
                            
                        }
                        .padding(.horizontal)
                        
                    }
                   
                    HStack{
                        TextField("Search jokes by term (e.g. pizza)", text: $viewModel.searchTerm)
                            .textFieldStyle(.roundedBorder)
                        Button("Search") {
                            Task {await viewModel.search()}
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal)
                    Group {
                        if viewModel.isLoading {
                            ProgressView("Searching jokes ...")
                                .padding(.top, 8)
                        }
                        
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        if !viewModel.isLoading {
                            List(viewModel.results) { joke in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(joke.joke)
                                        .font(.body)
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 4)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .listStyle(.plain)
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Search Jokes")
        }
    }
}


private struct JokeCategory: Identifiable{
    let id = UUID()
    let name: String
    let term: String
}

#Preview {
    SearchView()
}

