//
//  LikedJokesView.swift
//  Dad-A-Base
//
//  Created by Andrew Pitblado on 2026-03-15.
//

import SwiftUI
import SwiftData

struct LikedJokesView: View {
    @Query(sort: \FavoriteJoke.dateAdded, order: .reverse) private var favorites: [FavoriteJoke]
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack{
            ZStack {
                Color("LikedBackground")
                    .ignoresSafeArea()
                VStack {
                    
                    if favorites.isEmpty {
                        Text("You haven't liked any jokes yet! Go back to the Home tab and like some")
                            .foregroundStyle(Color("PrimaryText"))
                            .background(Color("PrimaryBackground").opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        List {
                            ForEach(favorites) {
                                favorite in Text(favorite.text)
                                    .foregroundStyle(Color("PrimaryText"))
                                    .padding(.vertical, 8)
                                    .listRowBackground(Color("PrimaryBackground").opacity(0.75))
                                    .multilineTextAlignment(.leading)
                                }
                                .onDelete(perform: deleteFavorites)
                            }
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                        }
                    }
                    
                }
            .navigationTitle("Liked Jokes")
        }
           

        
    }
    
    private func deleteFavorites(at offsets: IndexSet) {
            for index in offsets {
                modelContext.delete(favorites[index])
            }

            do {
                try modelContext.save()
            } catch {
                print("Failed to delete favorite jokes: \(error.localizedDescription)")
            }
        }
}



#Preview{
    LikedJokesView()
}
