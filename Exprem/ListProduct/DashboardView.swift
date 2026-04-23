//
//  DashboardView.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Product.expiryDate) private var products: [Product]

    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .expiredSoon
    @State private var showScanProductName = false
    @State private var draft = ProductDraft()
    
    private var headerText = ["Watch Out!", "Alertt!!!", "Your Items"]
    private var subHeaderText = ["Your items are expiring soon!", "Your items are expired, DO NOT USE IT!!", "Maintain your items"]
    
    private var allItems: [Product] {
        products
    }

    private var searchedItems: [Product] {
        if searchText.isEmpty { return allItems }
        return allItems.filter { $0.nameProduct.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredExpiredSoon: [Product] {
        searchedItems
            .filter { daysUntilExpiry(for: $0) >= 0 && daysUntilExpiry(for: $0) <= 7 }
            .sorted { $0.expiryDate < $1.expiryDate }
    }

    private var filteredExpired: [Product] {
        searchedItems
            .filter { daysUntilExpiry(for: $0) < 0 }
            .sorted { $0.expiryDate > $1.expiryDate }
    }

    private var filteredNextMonth: [Product] {
        searchedItems
            .filter { daysUntilExpiry(for: $0) >= 8 && daysUntilExpiry(for: $0) <= 30 }
            .sorted { $0.expiryDate < $1.expiryDate }
    }

    private var filteredLong: [Product] {
        searchedItems
            .filter { daysUntilExpiry(for: $0) > 30 }
            .sorted { $0.expiryDate < $1.expiryDate }
    }

    private var isCurrentSegmentEmpty: Bool {
        switch selectedFilter {
        case .expiredSoon:   return filteredExpiredSoon.isEmpty
        case .expiredAlready: return filteredExpired.isEmpty
        case .all:            return filteredExpiredSoon.isEmpty && filteredExpired.isEmpty
                                   && filteredNextMonth.isEmpty && filteredLong.isEmpty
        }
    }

    var body: some View {
        VStack{
            VStack{
                if selectedFilter == .expiredSoon {
                    HStack{
                        Text(headerText[0])
                            .foregroundStyle(theme.statusExpiredSoon)
                            .font(.largeTitle.weight(.semibold))
                            .multilineTextAlignment(.leading)
                            .padding(.leading, 16)
                        Spacer()
                    }
                    HStack{
                        Text(subHeaderText[0])
                            .foregroundStyle(theme.statusExpiredSoon)
                            .font(.subheadline.weight(.medium))
                            .multilineTextAlignment(.leading)
                            .padding(.leading, 16)
                        Spacer()
                    }
                }
                if selectedFilter == .expiredAlready {
                    HStack{
                        Text(headerText[1])
                            .foregroundStyle(theme.statusExpired)
                            .font(.largeTitle.weight(.semibold))
                            .multilineTextAlignment(.leading)
                            .padding(.leading, 16)
                        Spacer()
                    }
                    HStack{
                        Text(subHeaderText[1])
                            .foregroundStyle(theme.statusExpired)
                            .font(.subheadline.weight(.medium))
                            .multilineTextAlignment(.leading)
                            .padding(.leading, 16)
                        Spacer()
                    }
                }
                if selectedFilter == .all {
                    HStack{
                        Text(headerText[2])
                            .foregroundStyle(theme.appBlue)
                            .font(.largeTitle.weight(.semibold))
                            .multilineTextAlignment(.leading)
                            .padding(.leading, 16)
                        Spacer()
                    }
                    HStack{
                        Text(subHeaderText[2])
                            .foregroundStyle(theme.appBlue)
                            .font(.subheadline.weight(.medium))
                            .multilineTextAlignment(.leading)
                            .padding(.leading, 16)
                        Spacer()
                    }
                }
            }.padding(.bottom, 8)
            
            List {
                if isCurrentSegmentEmpty {
                    Section {
                        VStack(){
                            Spacer(minLength: 180)
                            HStack{
                                Spacer()
                                emptyStateView
                                Spacer()
                            }
                        }.listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                } else {
                    if selectedFilter == .expiredSoon || selectedFilter == .all {
                        if !filteredExpiredSoon.isEmpty {
                            Section(header: Text("Expired Soon").foregroundColor(theme.statusExpiredSoon)) {
                                ForEach(filteredExpiredSoon) { item in
                                    ProductCardView(item: item, onDone: markDone)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                }
                            }
                        }
                    }

                    if selectedFilter == .expiredAlready || selectedFilter == .all {
                        if !filteredExpired.isEmpty {
                            Section(header: Text("Already Expired").foregroundColor(theme.statusExpired)) {
                                ForEach(filteredExpired) { item in
                                    ProductCardView(item: item, onDone: markDone)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                }
                            }
                        }
                    }

                    if selectedFilter == .all {
                        if !filteredNextMonth.isEmpty {
                            Section(header: Text("Next Month").foregroundColor(theme.statusLong)) {
                                ForEach(filteredNextMonth) { item in
                                    ProductCardView(item: item, onDone: markDone)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                }
                            }
                        }

                        if !filteredLong.isEmpty {
                            Section(header: Text("Safe to Use")
                                .foregroundColor(theme.statusLong)) {
                                ForEach(filteredLong) { item in
                                    ProductCardView(item: item, onDone: markDone)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                }
                            }
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
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .background(.ultraThinMaterial)
            }
            .searchable(text: $searchText, prompt: "Search products")
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()
                    Button {
                        draft = ProductDraft()
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
                ScanProductNameView(origin: .onboarding, draft: $draft)
                    .appTheme(theme)
            }
            .onReceive(NotificationCenter.default.publisher(for: .returnToDashboard)) { _ in
                showScanProductName = false
            }
        }

        
        }
    private func daysUntilExpiry(for item: Product) -> Int {
        Calendar.current.dateComponents([.day], from: Date(), to: item.expiryDate).day ?? 0
    }

    private func markDone(_ product: Product) {
        ProductImageStore.deleteImage(filename: product.thumbnailPath)
        modelContext.delete(product)
        try? modelContext.save()
    }
    
    private var emptyStateView: some View {
        VStack() {
            Spacer()
            Image(systemName: "basket")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No groceries yet")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Tap + to add your first product")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

#Preview {
    DashboardView()
}
