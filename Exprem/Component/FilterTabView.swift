//
//  FilterTabView.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//

import SwiftUI

enum FilterOption: String, CaseIterable{
    case all = "All"
    case upcoming = "Upcoming"
    case stillLong = "Still Long"
    case expired = "Expired"
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
    FilterTabView(selectedTab: .constant(.all))
}
