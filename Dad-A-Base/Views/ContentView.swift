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
                            .antialiased(true)
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 400)
                            .scaleEffect(2.0)
                            .clipShape(Rectangle())
                            .clipped()
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
                        viewModel.toggleFavorite()
                    } label: {
                        Label(
                            viewModel.isFavorite ? "Liked" : "Like",
                            systemImage: viewModel.isFavorite ? "heart.fill" : "heart"
                        )
                    }
                    .padding()
                    .background(Color("LikeButton").opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(Color("PrimaryText"))
                    .padding(10)

                    ShareLink(
                        item: viewModel.currentJokeText,
                        subject: Text("Dad Joke of the Day"),
                        message: Text("Check out this dad joke!")
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .padding()
                    .background(viewModel.canShare ? Color("PrimaryBackground").opacity(0.8) : Color.gray.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(Color("PrimaryText"))
                    .padding(10)
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
                .background(Color("PrimaryBackground"))
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
