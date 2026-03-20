//
//  ContentView.swift
//  Dad-A-Base
//
//  Created by Andrew Pitblado on 2026-03-13.
//


import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var viewModel = JokeViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var toastMessage = ""
    @State private var showToast = false
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoriteJoke.dateAdded, order: .reverse) private var favorites: [FavoriteJoke]

    private var isCurrentJokeFavorite: Bool {
        if case .success(let joke) = viewModel.jokeState {
            return favorites.contains { $0.text == joke }
        }
        return false
    }

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            VStack {
                Text("Here is your dad joke of the day!")
                    .foregroundStyle(Color("PrimaryText"))
                    .font(.title)
                    .padding()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .background(Color("PrimaryBackground"))
                    .padding(.top, 50)

                Spacer()

                ZStack {
                    Image(colorScheme == .dark ? "DadSignDark" : "DadSign")
                            .resizable()
                            .interpolation(.high)
                            
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 400)
                            .scaleEffect(2.0)
                            
                            
                            .padding()
                        
                        overlayContent
                            .frame(maxWidth: 400, maxHeight: 300)
                            .offset(y: -70)
                            
                }
                Rectangle()
                    .fill(Color("PrimaryBackground"))
                    .frame(height: 25)
                    .offset(y: -50)
                    

                HStack {
                    Button {
                        toggleFavoriteForCurrentJoke()
                        
                    } label: {
                        Label(
                            isCurrentJokeFavorite ? "Liked" : "Like",
                            systemImage: isCurrentJokeFavorite ? "heart.fill" : "heart"
                        )
                    }
                    .padding()
                    .background(Color("LikeButton").opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(Color("PrimaryText"))
                    .padding(8)

                    ShareLink(
                        item: "Check out this dad joke:\n\n\(viewModel.currentJokeText)",
                        subject: Text("Dad Joke")){
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .padding()
                    .background(viewModel.canShare ? Color("PrimaryBackground").opacity(0.8) : Color.gray.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(Color("PrimaryText"))
                    .padding(8)
                    .disabled(!viewModel.canShare)

                    Button {
                        Task { await viewModel.fetchJoke() }
                    } label: {
                        Label("New Joke", systemImage: "arrow.clockwise")
                    }
                    .padding()
                    .background(Color("JokeButton").opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(Color("PrimaryText"))
                    .padding(5)
                }

                Spacer()
            }
        }
        .task {
            await viewModel.fetchJoke()
                
        }
        .animation(.spring(duration: 0.35), value: viewModel.currentJokeText)
        .sensoryFeedback(.success, trigger: toastMessage) {
            _, newValue in
            newValue == "Joke liked"
        }
        .sensoryFeedback(.warning, trigger: toastMessage) {
            _, newValue in
            newValue == "Removed from liked jokes"
        }
        .sensoryFeedback(.success, trigger: viewModel.jokeState) {
            _, newValue in
            if case .success = newValue { return true }
            return false
        }
        
        .overlay(alignment: .init(horizontal: .center, vertical: .bottom)) {
            if showToast {
                Text(toastMessage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("PrimaryText"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color("PrimaryBackground").opacity(0.9))
                    .clipShape(Capsule())
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func toggleFavoriteForCurrentJoke() {
        guard case .success(let joke) = viewModel.jokeState else { return }
        do {
            if let existing = favorites.first(where: { $0.text == joke }) {
                modelContext.delete(existing)
                toastMessage = "Removed from liked jokes"
            } else {
                modelContext.insert(FavoriteJoke(text: joke))
                toastMessage = "Joke liked"
            }

            try modelContext.save()
            showToastTemporarily()
        } catch {
            print("Failed to save favorite joke: \(error.localizedDescription)")
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

    @ViewBuilder
    private var overlayContent: some View {
        switch viewModel.jokeState {
        case .loading:
            VStack(spacing: 8) {
                ProgressView()
                    .tint(.black)
                Text("Loading your dad joke...")
                    .font(.subheadline)
                    .foregroundStyle(Color("PrimaryText"))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color("PrimaryBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 8))

        case .success(let joke):
            Text(joke)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(5)
                .padding(.horizontal, 5)
                .padding(.vertical, 10)
                .minimumScaleFactor(0.75)
                .foregroundStyle(Color("PrimaryText"))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

        case .error(let message):
            VStack(spacing: 8) {
                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.black)

                Button("Try Again") {
                    Task { await viewModel.fetchJoke() }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    ContentView()
}
