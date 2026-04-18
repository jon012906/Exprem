//
//  ContentView.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack{
            DashboardView()
        }
        .appTheme(colorScheme == .dark ? .dark : .light)
    }
}

#Preview {
    ContentView()
}
