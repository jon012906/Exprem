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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)

            HStack {
                Text(formatDate(date))
                    .foregroundColor(.blue)

                Spacer()

                Image(systemName: "calendar")
                    .foregroundColor(.blue)

                Image(systemName: "camera")
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
