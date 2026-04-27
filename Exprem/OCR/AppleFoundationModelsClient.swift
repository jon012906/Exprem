//
//  AppleFoundationModelsClient.swift
//  Exprem
//
//  Created by Jon on 27/04/26.
//

import Foundation
import FoundationModels

struct ProductExtractionResult {
    let name: String?
    let expiryDate: String?
}

final class AppleFoundationModelsClient: FoundationModelPrompting {
    @Generable
    struct Extraction {
        @Guide(description: """
        Nama merek dan varian utama produk. Format: 'MEREK VARIAN'.
        Contoh valid: 'LOTTE XYLITOL', 'INDOMIE GORENG', 'AQUA', 'TEH BOTOL SOSRO'.
        WAJIB mengoreksi typo OCR menggunakan kandidat 'alt:' (XYLITQ/XYLITO/XYLIT -> XYLITOL).
        DILARANG mengisi dengan deskripsi generik: 'Permen Karet', 'Sugar Free', 'Rasa Jeruk', \
        'Rasa Jeruk Nipis', 'Japan Brand', 'Chewing Gum', 'Mie Instan', 'Air Mineral'.
        DILARANG mengisi dengan produsen (PT/CV/Ltd/Inc/Tbk), alamat, atau kode regulasi (BPOM/SNI/HALAL).
        Kosongkan string bila tidak ada merek yang terbaca jelas.
        """)
        let name: String

        @Guide(description: """
        Tanggal kedaluwarsa dalam format dd/MM/yyyy.
        Cari label EXP/ED/BB/Best Before/Use Before/Kedaluwarsa. Abaikan tanggal produksi (MFG).
        Bila hanya bulan+tahun (mis. 'DES 2025'), gunakan hari 01 (hasil: '01/12/2025').
        Tahun 2 digit tambahkan 2000.
        Kosongkan string bila tidak ada tanggal kedaluwarsa.
        """)
        let expiryDate: String
    }

    private let session: LanguageModelSession?

    init?() {
        switch SystemLanguageModel.default.availability {
        case .available:
            self.session = LanguageModelSession(instructions: Self.systemInstructions)
        case .unavailable:
            self.session = nil
        @unknown default:
            self.session = nil
        }
    }

    func extract(from ocrText: String) async throws -> ProductExtractionResult {
        guard let session else {
            throw NSError(domain: "AppleFoundationModelsClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Language model not available on this device"])
        }

        let response = try await session.respond(
            to: Self.buildPrompt(ocrText: ocrText),
            generating: Extraction.self,
            options: GenerationOptions(temperature: 0.1)
        )
        let out = response.content
        return ProductExtractionResult(
            name: out.name.nilIfEmpty,
            expiryDate: out.expiryDate.nilIfEmpty
        )
    }

    private static let systemInstructions = """
    Anda menerima teks OCR dari kemasan produk berbahasa Indonesia. Tugas: ekstrak \
    NAMA MEREK produk dan TANGGAL KEDALUWARSA.

    Konvensi baris OCR:
    - Baris diawali "[MENONJOL]" = teks besar/dominan di kemasan. Ini hampir selalu \
      bagian dari MEREK atau VARIAN utama. Prioritaskan baris ini.
    - Bagian "| alt: X, Y" = kandidat OCR alternatif. Gunakan untuk mengoreksi typo.
    - Baris "[---]" hanyalah pemisah bagian atas/bawah gambar; cari di kedua bagian.

    Aturan ekstraksi:
    1. Gabungkan beberapa baris [MENONJOL] bila saling melengkapi menjadi satu nama.
    2. Urutan natural: MEREK dulu, lalu VARIAN/TIPE (contoh: 'LOTTE XYLITOL', \
       bukan 'XYLITOL LOTTE').
    3. Perbaiki typo OCR menggunakan 'alt:' dan pengetahuan merek Indonesia umum.
    4. TOLAK kategori generik, bentuk kemasan, nama produsen, regulasi, alamat, berat/volume.
    """

    private static func buildPrompt(ocrText: String) -> String {
        """
        Contoh-contoh ekstraksi yang BENAR:

        --- Contoh 1 ---
        OCR:
        [MENONJOL] LOTTE | alt: LOTE, LOTT
        [MENONJOL] XYLITO | alt: XYLITQ, XYLIT
        [MENONJOL] Japan Brand | alt: Japan Band
        [MENONJOL] RASA JERUK NIPIS
        Permen Karet
        Sugar Free Chewing
        55g (38 butir)
        EXP 12/2025
        Jawaban:
        name: "LOTTE XYLITOL"
        expiryDate: "01/12/2025"

        --- Contoh 2 ---
        OCR:
        [MENONJOL] INDOMIE | alt: INDOME
        [MENONJOL] GORENG
        Mie Instan
        Best before: 15 Mar 2027
        Jawaban:
        name: "INDOMIE GORENG"
        expiryDate: "15/03/2027"

        --- Contoh 3 ---
        OCR:
        [MENONJOL] AQUA | alt: AQQUA
        Air Mineral
        600 ml
        Kedaluwarsa: 30/06/2026
        Jawaban:
        name: "AQUA"
        expiryDate: "30/06/2026"

        --- Ekstrak sekarang ---
        OCR:
        \(ocrText)
        """
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}