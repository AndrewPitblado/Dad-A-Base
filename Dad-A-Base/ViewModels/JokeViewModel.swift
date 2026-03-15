//
//  JokeViewModel.swift
//  Dad-A-Base
//
//  Created by Andrew Pitblado on 2026-03-14.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class JokeViewModel: ObservableObject {
    
    enum JokeState: Equatable {
        case loading
        case success(String)
        case error(String)
    }

    @Published var jokeState: JokeState = .loading

    var currentJokeText: String {
        switch jokeState {
        case .loading:
            return "Loading your dad joke..."
        case .success(let joke):
            return joke
        case .error(let message):
            return message
        }
    }

    var canShare: Bool {
        if case .success = jokeState { return true }
        return false
    }

    func fetchJoke() async {
        jokeState = .loading

        guard let url = URL(string: "https://icanhazdadjoke.com/") else {
            jokeState = .error("Invalid joke service URL.")
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Dad-A-Base iOS App", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                jokeState = .error("Couldn’t load a joke right now.")
                return
            }

            let decoded = try JSONDecoder().decode(DadJokeResponse.self, from: data)
            jokeState = .success(decoded.joke)
        } catch {
            jokeState = .error("Network error. Please try again.")
        }
    }
}

private struct DadJokeResponse: Decodable {
    let joke: String
}
