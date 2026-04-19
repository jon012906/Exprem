//
//  AppTheme.swift
//  Exprem
//
//  Created by Jon on 18/04/26.
//

import SwiftUI

struct AppTheme {
    // MARK: APP Colors
    let appBlue: Color
    let appBlueSoft: Color
    let appBackground: Color
    let appCard: Color
    let appSurfaceMuted: Color
    let appBorder: Color
    let appTextPrimary: Color
    let appTextSecondary: Color
    let appPlaceholder:Color

    // MARK: Status Colors
    let statusUpcoming: Color
    let statusUpcomingBg: Color
    let statusLong: Color
    let statusLongBg: Color
    let statusExpired: Color
    let statusExpiredBg: Color

    static let light = AppTheme(
        appBlue: Color(red: 0.114, green: 0.306, blue: 0.847),
        appBlueSoft: Color(red: 0.859, green: 0.918, blue: 0.996),
        appBackground: Color(red: 0.961, green: 0.976, blue: 1.0),
        appCard: .white,
        appSurfaceMuted: Color(red: 0.84, green: 0.84, blue: 0.86),
        appBorder: Color(red: 0.851, green: 0.886, blue: 0.949),
        appTextPrimary: .primary,
        appTextSecondary: .secondary,
        appPlaceholder: Color(red: 0.6, green: 0.6, blue: 0.6),
        statusUpcoming: Color(red: 0.851, green: 0.467, blue: 0.024),
        statusUpcomingBg: Color(red: 0.996, green: 0.953, blue: 0.78),
        statusLong: Color(red: 0.145, green: 0.388, blue: 0.922),
        statusLongBg: Color(red: 0.859, green: 0.918, blue: 0.996),
        statusExpired: Color(red: 0.863, green: 0.149, blue: 0.149),
        statusExpiredBg: Color(red: 0.996, green: 0.886, blue: 0.886)
    )

    static let dark = AppTheme(
        appBlue: Color(red: 0.373, green: 0.565, blue: 0.996),
        appBlueSoft: Color(red: 0.114, green: 0.208, blue: 0.353),
        appBackground: Color(red: 0.043, green: 0.071, blue: 0.125),
        appCard: Color(red: 0.071, green: 0.102, blue: 0.165),
        appSurfaceMuted: Color(red: 0.122, green: 0.153, blue: 0.224),
        appBorder: Color(red: 0.224, green: 0.278, blue: 0.373),
        appTextPrimary: .primary,
        appTextSecondary: .secondary,
        appPlaceholder: Color(red: 0.5, green: 0.5, blue: 0.5),
        statusUpcoming: Color(red: 0.98, green: 0.737, blue: 0.259),
        statusUpcomingBg: Color(red: 0.263, green: 0.188, blue: 0.067),
        statusLong: Color(red: 0.482, green: 0.678, blue: 0.996),
        statusLongBg: Color(red: 0.086, green: 0.176, blue: 0.322),
        statusExpired: Color(red: 0.988, green: 0.443, blue: 0.443),
        statusExpiredBg: Color(red: 0.337, green: 0.098, blue: 0.098)
    )
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.light
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

extension View {
    func appTheme(_ theme: AppTheme) -> some View {
        environment(\.appTheme, theme)
    }
}
