//
//  DashboardView.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//

import SwiftUI

// Mock Data
let mockUpcoming: [ProductItem] = [
    ProductItem(name: "Milk", expiryDate: Date().addingTimeInterval(86400 * 2)),
    ProductItem(name: "Bread", expiryDate: Date().addingTimeInterval(86400 * 1))
]

let mockNextMonth: [ProductItem] = [
    ProductItem(name: "Cheese", expiryDate: Date().addingTimeInterval(86400 * 20))
]

let mockLong: [ProductItem] = [
    ProductItem(name: "Canned Food", expiryDate: Date().addingTimeInterval(86400 * 60))
]

struct DashboardView: View {
    @Environment(\.appTheme) private var theme

    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .all
    @State private var showScanProductName = false
    
    // MARK: - Filtering
    
    var filteredUpcoming: [ProductItem] {
        if searchText.isEmpty { return mockUpcoming }
        return mockUpcoming.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var filteredNextMonth: [ProductItem] {
        if searchText.isEmpty { return mockNextMonth }
        return mockNextMonth.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var filteredLong: [ProductItem] {
        if searchText.isEmpty { return mockLong }
        return mockLong.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Body
    var body: some View {
            // Content Section
            List {
                if !filteredUpcoming.isEmpty {
                    Section(header: Text("Upcoming")
                        .foregroundColor(theme.statusUpcoming)) {
                        ForEach(filteredUpcoming) { item in
                            ProductCardView(item: item, onDone: { _ in })
                                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                }
                
                if !filteredNextMonth.isEmpty {
                    Section(header: Text("Next Month")
                        .foregroundColor(theme.statusLong)) {
                        ForEach(filteredNextMonth) { item in
                            ProductCardView(item: item, onDone: { _ in })
                                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                }
                
                if !filteredLong.isEmpty {
                    Section(header: Text("Still Long")
                        .foregroundColor(theme.statusLong)) {
                        ForEach(filteredLong) { item in
                            ProductCardView(item: item, onDone: { _ in })
                                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.appBackground)
            .listStyle(.insetGrouped)
            
            .safeAreaInset(edge: .top) {
                    FilterTabView(selectedTab: $selectedFilter)
                        .padding(.horizontal)
                        .padding(.top, -8)
                        .padding(.bottom, 8)
                        .background(.ultraThinMaterial)
            }
        
            //  Search
            .searchable(text: $searchText, prompt: "Search products")
            
            // Add Button
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()

                    Button {
                        showScanProductName = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(theme.appBlue)
                            .clipShape(Circle())
                            .shadow(color: theme.appBlue.opacity(0.28), radius: 6, x: 0, y: 3)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationDestination(isPresented: $showScanProductName) {
                ScanProductNameView(origin: .onboarding)
                    .appTheme(theme)
            }
            .onReceive(NotificationCenter.default.publisher(for: .returnToDashboard)) { _ in
                showScanProductName = false
            }
        }
}

    
#Preview {
    DashboardView()
}
