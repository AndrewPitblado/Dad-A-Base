//
//  AppToastView.swift
//  Dad-A-Base
//
//  Created by Andrew Pitblado on 2026-03-20.
//

import SwiftUI

struct AppToastView : View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color("PrimaryText"))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color("PrimaryBackground").opacity(0.9))
            .clipShape(Capsule())
    }
}
