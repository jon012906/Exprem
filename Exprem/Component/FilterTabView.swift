//
//  FilterTabView.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//

import SwiftUI

enum FilterOption: String, CaseIterable{
    case expiredSoon = "Expired Soon"
    case expiredAlready = "Already Expired"
    case all = "All"
}

struct FilterTabView: View {
    @Binding var selectedTab: FilterOption
    var body: some View {
        // MARK: - Filter Tabs
        Picker("", selection: $selectedTab) {
                   ForEach(FilterOption.allCases, id: \.self) { filter in
                       Text(filter.rawValue).tag(filter)
                   }
               }
               .pickerStyle(.segmented)
    }
}

#Preview {
    FilterTabView(selectedTab: .constant(.expiredSoon))
}
