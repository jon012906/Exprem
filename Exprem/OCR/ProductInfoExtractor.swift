//
//  ProductInfoExtractor.swift
//  Exprem
//
//  Created by Jon on 23/04/26.
//

import Foundation

enum ProductInfoExtractorError: LocalizedError {
    case emptyOCRText
    case productNameNotFound
    case expiryDateNotFound

    var errorDescription: String? {
        switch self {
        case .emptyOCRText:
            return "Teks hasil OCR kosong."
        case .productNameNotFound:
            return "Nama produk tidak terbaca, coba foto ulang."
        case .expiryDateNotFound:
            return "Tanggal kedaluwarsa tidak terbaca, coba foto ulang."
        }
    }
}

final class FoundationProductInfoExtractor: ProductInfoExtracting {
    private let modelClient: FoundationModelPrompting?
    private var lastExtraction: (key: String, name: String, expiryDate: String)?

    init(modelClient: FoundationModelPrompting? = nil) {
        self.modelClient = modelClient ?? AppleFoundationModelsClient()
    }

    func extractProductName(from ocrText: String) async throws -> String {
        let normalized = ocrText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { throw ProductInfoExtractorError.emptyOCRText }
        let result = await extractBoth(from: normalized)
        guard !result.name.isEmpty else { throw ProductInfoExtractorError.productNameNotFound }
        return result.name
    }

    func extractExpiryDate(from ocrText: String) async throws -> String {
        let normalized = ocrText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { throw ProductInfoExtractorError.emptyOCRText }
        let result = await extractBoth(from: normalized)
        guard !result.expiryDate.isEmpty else { throw ProductInfoExtractorError.expiryDateNotFound }
        return result.expiryDate
    }

    private func extractBoth(from ocrText: String) async -> (name: String, expiryDate: String) {
        if let cached = lastExtraction, cached.key == ocrText {
            return (cached.name, cached.expiryDate)
        }

        let (topText, bottomText) = splitSections(ocrText)
        let dateSource = bottomText.isEmpty ? ocrText : bottomText

        var foundDate = highestDateString(in: dateSource)
        var foundName: String?

        if let modelClient,
           let result = try? await modelClient.extract(from: ocrText) {
            foundName = result.name
            if foundDate == nil, let raw = result.expiryDate {
                foundDate = formatDateString(raw) ?? raw
            }
        }

        if foundName == nil {
            let fallbackSource = topText.isEmpty ? ocrText : topText
            foundName = bestProductLine(from: fallbackSource) ?? bestProductLine(from: ocrText)
        }

        let result = (name: foundName ?? "", expiryDate: foundDate ?? "")
        if !result.name.isEmpty || !result.expiryDate.isEmpty {
            cache(ocrText, name: result.name, expiryDate: result.expiryDate)
        }
        return result
    }

    private func splitSections(_ text: String) -> (top: String, bottom: String) {
        let parts = text.components(separatedBy: "\n[---]\n")
        guard parts.count == 2 else { return ("", "") }
        return (parts[0], parts[1])
    }

    private func cache(_ key: String, name: String, expiryDate: String) {
        lastExtraction = (key: key, name: name, expiryDate: expiryDate)
    }

    private func bestProductLine(from text: String) -> String? {
        let blockedKeywords = [
            "exp", "expired", "kadaluarsa", "kedaluwarsa", "best before", "mfg", "produksi",
            "pt ", " pt.", "cv ", " cv.", " ltd", " inc", " corp", " tbk",
            "industries", "manufacturing", "distributor", "import",
            "pom ", "bpom", "halal", "sni ", "md ", "ml ",
            "kapsul", "kaplet", "tablet", "sachet", "softgel", "krim", "sirup",
            "losion", "lotion", "serum", "spray",
            "suplemen", "kesehatan", "supplement", "health",
            "disposable", "air mineral", "mineral water", "sabun", "tissue",
            "indonesia"
        ]

        let rawLines = text.components(separatedBy: .newlines)

        func stripAnnotations(_ line: String) -> String {
            var t = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.hasPrefix("[MENONJOL] ") {
                t = String(t.dropFirst("[MENONJOL] ".count))
            }
            if let altRange = t.range(of: " | alt: ") {
                t = String(t[..<altRange.lowerBound])
            }
            return t.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let prominent = rawLines
            .filter { $0.hasPrefix("[MENONJOL] ") }
            .map(stripAnnotations)

        let all = rawLines.map(stripAnnotations)

        func passes(_ line: String) -> Bool {
            guard (3...40).contains(line.count) else { return false }
            let lowercased = line.lowercased()
            guard !blockedKeywords.contains(where: { lowercased.contains($0) }) else { return false }
            guard line.range(of: "[A-Za-z]", options: .regularExpression) != nil else { return false }
            let digitRatio = Double(line.filter(\.isNumber).count) / Double(line.count)
            return digitRatio < 0.5
        }

        let candidates = prominent.filter(passes).isEmpty
            ? all.filter(passes)
            : prominent.filter(passes)

        guard !candidates.isEmpty else { return nil }

        if candidates.count >= 2, candidates[0].count <= 20, candidates[1].count <= 20 {
            return "\(candidates[0]) \(candidates[1])"
        }
        return candidates.first
    }

    private func highestDateString(in text: String) -> String? {
        guard let date = highestDate(in: text) else { return nil }
        return displayFormatter.string(from: date)
    }

    private func highestDate(in text: String) -> Date? {
        let patterns = [
            #"\b\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}\b"#,
            #"\b\d{4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,2}\b"#,
            #"(?<!\d[\/\-])\b\d{1,2}[\/\-]\d{2,4}\b(?![\/\-]\d)"#,
            #"(?<!\d[\/\-])\b\d{4}[\/\-]\d{1,2}\b(?![\/\-]\d)"#,
            #"\b\d{1,2}\s+\d{4}\b"#,
            #"\b\d{4}\s+\d{1,2}\b"#,
            #"\b\d{1,2}\s+[A-Za-z]{3,12}\s+\d{2,4}\b"#,
            #"\b[A-Za-z]{3,12}\s+\d{2,4}\b"#
        ]

        let matches = patterns.flatMap { pattern -> [String] in
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            return regex.matches(in: text, range: range).compactMap {
                guard let stringRange = Range($0.range, in: text) else { return nil }
                return String(text[stringRange])
            }
        }

        let dates = matches.compactMap(formatDateString).compactMap { displayFormatter.date(from: $0) }
        return dates.max()
    }

    private func formatDateString(_ raw: String) -> String? {
        let normalized = raw
            .replacingOccurrences(of: "-", with: "/")
            .replacingOccurrences(of: ".", with: "/")
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: "/")

        if let monthYearDate = parseMonthYearDate(from: normalized) {
            return displayFormatter.string(from: monthYearDate)
        }

        if let monthNameDate = parseMonthNameDate(from: raw) {
            return displayFormatter.string(from: monthNameDate)
        }

        for formatter in parseFormatters {
            if let date = formatter.date(from: normalized) {
                return displayFormatter.string(from: date)
            }
        }
        return nil
    }

    private func parseMonthNameDate(from raw: String) -> Date? {
        let normalized = raw
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "/", with: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        for formatter in monthNameFormatters {
            if let date = formatter.date(from: normalized) {
                return date
            }
        }
        return nil
    }

    private func parseMonthYearDate(from raw: String) -> Date? {
        let parts = raw
            .split(separator: "/")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

        guard parts.count == 2 else { return nil }

        let first = Int(parts[0])
        let second = Int(parts[1])
        guard let first, let second else { return nil }

        let month: Int
        let year: Int

        if parts[0].count == 4 {
            year = first
            month = second
        } else if parts[1].count == 4 || second > 31 {
            month = first
            year = second
        } else {
            month = first
            year = second >= 70 ? 1900 + second : 2000 + second
        }

        guard (1...12).contains(month), (1900...2100).contains(year) else { return nil }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.timeZone = TimeZone(secondsFromGMT: 0)

        return Calendar(identifier: .gregorian).date(from: components)
    }

    private let parseFormatters: [DateFormatter] = {
        let formats = [
            "dd/MM/yyyy", "d/M/yyyy", "dd/MM/yy", "d/M/yy",
            "yyyy/MM/dd", "yyyy/M/d",
            "MM/yyyy", "M/yyyy", "MM/yy", "M/yy",
            "yyyy/MM", "yyyy/M"
        ]
        return formats.map { format in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "id_ID")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.dateFormat = format
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return formatter
        }
    }()

    private let monthNameFormatters: [DateFormatter] = {
        let locales = [Locale(identifier: "id_ID"), Locale(identifier: "en_US_POSIX")]
        let formats = [
            "dd MMM yyyy", "d MMM yyyy", "dd MMMM yyyy", "d MMMM yyyy",
            "dd MMM yy", "d MMM yy", "dd MMMM yy", "d MMMM yy",
            "MMM yyyy", "MMMM yyyy", "MMM yy", "MMMM yy"
        ]
        let defaultDate = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2000, month: 1, day: 1))

        return locales.flatMap { locale in
            formats.map { format in
                let formatter = DateFormatter()
                formatter.locale = locale
                formatter.calendar = Calendar(identifier: .gregorian)
                formatter.dateFormat = format
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                formatter.defaultDate = defaultDate
                return formatter
            }
        }
    }()

    private lazy var displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}