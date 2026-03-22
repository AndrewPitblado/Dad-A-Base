//
//  JokeSearchViewModel.swift
//  Dad-A-Base
//
//  Created by Andrew Pitblado on 2026-03-14.
//

import Foundation
import Combine

@MainActor

final class JokeSearchViewModel: ObservableObject {
    @Published var searchTerm = ""
    @Published var results: [SearchedJoke] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func search() async {
        let trimmed = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter a search term."
            results = []
            return
        }
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            let jokes = try await DadJokeAPI.search(term: trimmed)
            results = jokes
            if jokes.isEmpty {
                errorMessage = "No jokes found for \"\(trimmed)\"."
            }
        }
        catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }
    }

    func clearSearchState() {
        results = []
        errorMessage = nil
    }
}

enum DadJokeAPI {
    static func search(term: String) async throws -> [SearchedJoke] {
        var components = URLComponents(string: "https://icanhazdadjoke.com/search")!
        components.queryItems = [URLQueryItem(name: "term", value: term), URLQueryItem(name: "limit", value: "20")]
        var request = URLRequest(url: components.url!)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Dad-A-Base iOS App", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
        return decoded.results
    }
}
struct SearchResponse: Decodable {
    let results: [SearchedJoke]
}

struct SearchedJoke: Identifiable, Decodable {
    let id: String
    let joke: String
}
