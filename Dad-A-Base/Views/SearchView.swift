//
//  SearchView.swift
//  Dad-A-Base
//
//  Created by Andrew Pitblado on 2026-03-13.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @StateObject private var viewModel = JokeSearchViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Query(sort: \FavoriteJoke.dateAdded, order: .reverse) private var favorites: [FavoriteJoke]
    
    @State private var toastMessage = ""
    @State private var showToast = false
    
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
                Color(colorScheme == .dark ? .black : .white)
                
                    .ignoresSafeArea()
                
                VStack (spacing: 12){
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories) { category in
                                Button(category.name) {
                                    viewModel.searchTerm = category.term
                                    Task {                                    await viewModel.search()}
                                }
                                .foregroundStyle(Color("PrimaryText"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .glassEffect(.regular.tint(Color("PrimaryBackground")).interactive())
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
                        ZStack{
                            
                            Image(colorScheme == .dark ? "DarkBbq" : "Bbq")
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .clipped()
                            
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
                                            .foregroundStyle(Color("PrimaryText"))
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 4)
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        ShareLink(item: "Check out this dad joke:\n\(joke.joke)") {
                                            Label("Share", systemImage: "square.and.arrow.up")
                                        }
                                        .tint(colorScheme == .dark ? .black : .indigo)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button {
                                            toggleFavorite(for: joke.joke)
                                        } label: {
                                            Label("Like", systemImage: "heart.fill")
                                        }
                                        .tint(colorScheme == .dark ? .red : .pink)
                                    }
                                    
                                    
                                    .padding(.horizontal, 20)
                                    
                                    
                                }
                                .listStyle(.plain)
                                .glassEffect(in: .rect(cornerRadius: 12))
                                .mask(RoundedRectangle(cornerRadius: 12))
                                
                                
                            }
                        }
                        .padding(.top)
                    }
                }
                .navigationTitle("Search for Jokes")
                
                
                
                
                
                
                
            }
            
        }
        .sensoryFeedback(.success, trigger: toastMessage) { _, newValue in
            newValue == "Joke liked"
        }
        .sensoryFeedback(.warning, trigger: toastMessage) { _, newValue in
            newValue == "Removed from liked jokes"
        }
        .overlay(alignment: .bottom) {
            if showToast {
                AppToastView(message: toastMessage)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom)
                        .combined(with: .opacity))
            }
        }
    }
    
    private func toggleFavorite(for jokeText: String) {
        if let existing = favorites.first(where: { $0.text == jokeText }) {
            modelContext.delete(existing)
            toastMessage = "Removed from liked jokes"
        } else {
            modelContext.insert(FavoriteJoke(text: jokeText))
            toastMessage = "Joke liked"
        }

        do {
            try modelContext.save()
            showToastTemporarily()
        } catch {
            print("Failed to save favorite from search: \(error.localizedDescription)")
        }
    }
    private func showToastTemporarily() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showToast = false
            }
        }
    }
    
    private struct JokeCategory: Identifiable{
        let id = UUID()
        let name: String
        let term: String
    }
}
    #Preview {
        SearchView()
    }

