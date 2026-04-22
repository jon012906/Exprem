import Foundation

struct ProductDraft: Equatable {
    var nameProduct: String
    var expiryDate: Date
    var note: String
    var reminderStartDate: Date?
    var thumbnailPath: String?
    var thumbnailData: Data?

    init(
        nameProduct: String = "",
        expiryDate: Date = Date(),
        note: String = "",
        reminderStartDate: Date? = Date(),
        thumbnailPath: String? = nil,
        thumbnailData: Data? = nil
    ) {
        self.nameProduct = nameProduct
        self.expiryDate = expiryDate
        self.note = note
        self.reminderStartDate = reminderStartDate
        self.thumbnailPath = thumbnailPath
        self.thumbnailData = thumbnailData
    }

    init(product: Product) {
        self.nameProduct = product.nameProduct
        self.expiryDate = product.expiryDate
        self.note = product.note
        self.reminderStartDate = product.reminderStartDate
        self.thumbnailPath = product.thumbnailPath
        self.thumbnailData = nil
    }
}
