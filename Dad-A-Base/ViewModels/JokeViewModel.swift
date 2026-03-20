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
    private let lastFetchKey = "lastJokeFetchDate"
    private let lastJokeTextKey = "lastJokeText"
    private let autoRefreshInterval: TimeInterval = 24*60*60 // one day

    init() {
        if let cachedJoke = UserDefaults.standard.string(forKey: lastJokeTextKey),
           !cachedJoke.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            jokeState = .success(cachedJoke)
        }
    }

    var currentJokeText: String {
        if case .success(let joke) = jokeState{
            return joke
        }
        return ""
    }

    var canShare: Bool {
        if case .success = jokeState { return true }
        return false
    }

    
    func fetchJokeIfNeeded(force: Bool = false) async {
        if force || shouldAutoFetch {
            await fetchJoke()
            return
        }

        if case .success = jokeState {
            return
        }

        if let cachedJoke = UserDefaults.standard.string(forKey: lastJokeTextKey),
           !cachedJoke.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            jokeState = .success(cachedJoke)
            return
        }

        await fetchJoke()
    }

     private var shouldAutoFetch: Bool {
         let defaults = UserDefaults.standard
         guard let lastFetch = defaults.object(forKey: lastFetchKey) as? Date else {
             return true
         }
         return Date().timeIntervalSince(lastFetch) >= autoRefreshInterval
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
            UserDefaults.standard.set(Date(), forKey: lastFetchKey)
            UserDefaults.standard.set(decoded.joke, forKey: lastJokeTextKey)
        } catch {
            jokeState = .error("Network error. Please try again.")
        }
    }
}

private struct DadJokeResponse: Decodable {
    let joke: String
}
