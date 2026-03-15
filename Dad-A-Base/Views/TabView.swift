//
//  TabView.swift
//  Dad-A-Base
//
//  Created by Andrew Pitblado on 2026-03-13.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            
            Tab("Home", systemImage: "house"){
                ContentView()
            }
            
            Tab("Search", systemImage: "magnifyingglass"){
                SearchView()
            }
            
            Tab("Profile", systemImage: "person"){
                
                ContentView()
            }
        }
    }
}

#Preview {
    MainTabView()
}
