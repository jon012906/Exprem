//
//  DataField.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//

import SwiftUI

struct DateField: View {
    var title: String
    @Binding var date: Date
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(theme.appTextSecondary)

            HStack {
                Text(formatDate(date))
                    .foregroundColor(theme.appBlue)

                Spacer()

                Image(systemName: "calendar")
                    .foregroundColor(theme.appBlue)

                Image(systemName: "camera")
                    .foregroundColor(theme.appBlue)
            }
            .padding()
            .background(theme.appBlueSoft)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
