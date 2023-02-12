//
//  PDFPageItem.swift
//  
//
//  Created by Óscar Morales Vivó on 2/11/23.
//

import Cocoa
import PDFKit

class PDFPageItem: NSCollectionViewItem {
    static var identifier: NSUserInterfaceItemIdentifier {
        return .init(rawValue: "\(Self.self)")
    }

    // MARK: - IBOutlets

    @IBOutlet private var widthConstraint: NSLayoutConstraint!
}

// MARK: - View Model

extension PDFPageItem {
    public var pdfPage: PDFPage? {
        get {
            super.representedObject as? PDFPage
        }

        set {
            super.representedObject = newValue
        }
    }
}

// MARK: - UI Management

extension PDFPageItem {
    private static let imageHeight = 200.0
    private static let thumbnailMaxSize = CGSize(width: imageHeight * sqrt(5.0), height: imageHeight)

    private func configure(with pdfPage: PDFPage?) {
        guard let pdfPage else {
            // Just cleanup and leave.
            imageView?.image = nil
            return
        }

        let thumbnailImage = pdfPage.thumbnail(of: Self.thumbnailMaxSize, for: .mediaBox)
        let thumbnailImageSize = thumbnailImage.size
        guard thumbnailImageSize != .zero, thumbnailImageSize.height > 0.0 else {
            // Just cleanup and leave.
            imageView?.image = nil
            return

        }

        imageView?.image = thumbnailImage
        widthConstraint.constant = Self.imageHeight * (thumbnailImageSize.width / thumbnailImageSize.height)
    }
}

// MARK: - NSViewController Overrides

extension PDFPageItem {
    override var representedObject: Any? {
        get {
            return super.representedObject
        }

        set {
            preconditionFailure("representedObject shouldn't be set directly on `PDFPageItem`")
        }
    }
}
