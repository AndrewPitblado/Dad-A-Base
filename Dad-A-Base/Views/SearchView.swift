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
    
    @State private var selectedCategory: UUID? = nil
    @State private var toastMessage = ""
    @State private var showToast = false
    @FocusState private var searchFieldIsFocused: Bool
    private let categories: [JokeCategory] = [
        .init(name: "Animals", term:"dog"),
        .init(name: "Food", term:"food"),
        .init(name: "Puns", term:"pun"),
        .init(name: "School", term:"school"),
        .init(name: "Tech", term: "computer")
    ]
    
   
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(colorScheme == .dark ? .black : .white)
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories) { category in
                                categoryButton(for: category)
                                
                            }
                        }
                        .padding(.horizontal)
                    }
                    searchBar
                    resultsSection
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
        .onChange(of: viewModel.searchTerm) { _, newValue in
            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                selectedCategory = nil
                viewModel.clearSearchState()
            }
        }
    }

    @ViewBuilder
    private var searchBar: some View {
        HStack {
            TextField("Search jokes by term (e.g. pizza)", text: $viewModel.searchTerm)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .focused($searchFieldIsFocused)
                

            if !viewModel.searchTerm.isEmpty {
                Button {
                    viewModel.searchTerm = ""
                    searchFieldIsFocused = false
                    selectedCategory = nil
                } label: {
                    Image(systemName: "x.circle.fill")
                        .foregroundStyle(.red)
                        .controlSize(.small)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
            }

            Button("Search") {
                Task { await viewModel.search() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var resultsSection: some View {
        ZStack {
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

            if !viewModel.isLoading && !viewModel.results.isEmpty {
                List(viewModel.results) { joke in
                    jokeRow(for: joke.joke)
                }
                .listStyle(.plain)
                .glassEffect(in: .rect(cornerRadius: 12))
                .mask(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    
    private func jokeRow(for text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(text)
                .font(.body)
                .foregroundStyle(Color("PrimaryText"))
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            ShareLink(item: "Check out this dad joke:\n\(text)") {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .tint(colorScheme == .dark ? .black : .indigo)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                toggleFavorite(for: text)
            } label: {
                Label("Like", systemImage: "heart.fill")
            }
            .tint(colorScheme == .dark ? .red : .pink)
        }
        .padding(.horizontal, 20)
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

    private func categoryButton(for category: JokeCategory) -> some View {
        Button(category.name) {
            viewModel.searchTerm = category.term
            selectedCategory = category.id
            Task {
                await viewModel.search()
            }
        }
        
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(selectedCategory == category.id ? .blue.opacity(0.8) : Color.clear)
        .glassEffect()
        .foregroundStyle(selectedCategory == category.id ? Color("PrimaryText") : Color("PrimaryText").opacity(0.75))
        .clipShape(Capsule())
        
        
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
