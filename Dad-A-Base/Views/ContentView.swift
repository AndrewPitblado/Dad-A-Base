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

    private var adaptivePrimaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var actionButtonPadding: EdgeInsets {
        EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
    }

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
                    .padding()
            
                    .font(.title)
                    .glassEffect(.regular.tint(Color("PrimaryBackground")).interactive())
                    
                    .shadow(color:Color("PrimaryText"),radius: 5)
                    .padding(.top, 50)
                
                //Count down timer until next joke refreshes - only shows when a joke is successfully loaded and counts down in real time
                if case .success = viewModel.jokeState {
                    
                    Text("Next dad joke in \(viewModel.timeUntilNextJokeSeconds) seconds")
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        
                        .foregroundStyle(adaptivePrimaryTextColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .glassEffect(.regular.tint(Color("PrimaryBackground")).interactive())
                        .shadow(color:Color("PrimaryText"),radius: 2)
                }

                Spacer()

                ZStack {
                    Image(colorScheme == .dark ? "DadSignDark" : "DadSign")
                        .resizable()
                        .interpolation(.high)
                    
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 400)
                        .scaleEffect(2.0)
                    
                    
                    
                    
                    overlayContent
                        .frame(maxWidth: 400, maxHeight: 300)
                        .offset(y: -70)
                    
                }
                    
                    HStack(spacing: 12) {
                        Button {
                            toggleFavoriteForCurrentJoke()
                            
                        } label: {
                            Label(
                                isCurrentJokeFavorite ? "Liked" : "Like",
                                systemImage: isCurrentJokeFavorite ? "heart.fill" : "heart"
                            )
                            .labelStyle(.titleAndIcon)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .allowsTightening(true)
                            .frame(maxWidth: .infinity)
                            .padding(actionButtonPadding)
                            .foregroundStyle(isCurrentJokeFavorite ? Color("PrimaryBackground") : adaptivePrimaryTextColor)
                        }
                        .buttonStyle(.glass(.regular.tint(Color("LikeButton")).interactive()))
                        
                        ShareLink(
                            item: "Check out this dad joke:\n\n\(viewModel.currentJokeText)",
                            subject: Text("Dad Joke")){
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .labelStyle(.titleAndIcon)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                    .allowsTightening(true)
                                    .frame(maxWidth: .infinity)
                                    .padding(actionButtonPadding)
                                    .foregroundStyle(viewModel.canShare ? adaptivePrimaryTextColor : Color.gray)
                            }
                            .buttonStyle(.glass(.regular.tint(viewModel.canShare ? Color("PrimaryBackground") : Color.gray).interactive()))
                            .disabled(!viewModel.canShare)
                        
                        Button {
                            Task { await viewModel.fetchJokeIfNeeded(force: true) }
                        } label: {
                            Label("New", systemImage: "arrow.clockwise")
                                .labelStyle(.titleAndIcon)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .allowsTightening(true)
                                .frame(maxWidth: .infinity)
                                .padding(actionButtonPadding)
                                .foregroundStyle(adaptivePrimaryTextColor)
                        }
                        .buttonStyle(.glass(.regular.tint(Color("JokeButton")).interactive()))
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 50)      // where the section starts (near feet)
                    .padding(.bottom, 40)
                    .frame(maxWidth: .infinity)
                    .background(alignment: .top) {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color("PrimaryBackground"))
                            .opacity(0.4)
                            .shadow(color:Color("PrimaryText"),radius: 5)
                            .ignoresSafeArea(edges: .bottom)
                    }
                        
                
            }
        }
        .task {
            await viewModel.fetchJokeIfNeeded()
                
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
                AppToastView(message: toastMessage)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom)
                        .combined(with: .opacity))
            }
        }
    }

    public func toggleFavoriteForCurrentJoke() {
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
