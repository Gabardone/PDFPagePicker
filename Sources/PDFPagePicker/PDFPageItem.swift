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
        .init(rawValue: "\(Self.self)")
    }

    override init(nibName _: NSNib.Name?, bundle _: Bundle?) {
        super.init(nibName: "PDFPageItem", bundle: .module)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public properties

    /// Configure this property so thumbnail size calculations track the actual display item size.
    var desiredSize: CGSize = PDFPageItem.defaultThumbnailSize

    // MARK: - IBOutlets

    @IBOutlet
    private var selectionEffect: NSVisualEffectView!

    @IBOutlet
    private var horizontalMargin: NSLayoutConstraint!

    @IBOutlet
    private var verticalMargin: NSLayoutConstraint!
}

// MARK: - View Model

extension PDFPageItem {
    public var pdfPage: PDFPage? {
        get {
            super.representedObject as? PDFPage
        }

        set {
            guard pdfPage != newValue else {
                return
            }

            super.representedObject = newValue

            configure(with: pdfPage)
        }
    }
}

// MARK: - UI Management

extension PDFPageItem {
    /**
     Since precalculating the sizes of the items is the safest thing to do with all of `NSCollectionView` jankiness,
     this method takes care of the matter so it can be called by the collection view controller proper.
     - Parameter pdfPage: The pdfPage we want to display.
     - Parameter withinSize: Maximum bounding size for the item.
     - Parameter margin: The margins we want to apply for selection display. Must be greater or equal than zero.
     - Returns: The desired item size for the above parameters. Will never be smaller than 2x margin no matter the value
     of the `withinSize` parameter.
     */
    public static func desiredSize(forPage pdfPage: PDFPage, contained withinSize: CGSize, margin: CGFloat) -> CGSize {
        let margin = max(margin, 0.0)
        let doubleMargin = 2.0 * margin
        guard withinSize.width > doubleMargin, withinSize.height > doubleMargin else {
            // Degenerate case, image woudlnt' show anyway.
            return .init(width: doubleMargin, height: doubleMargin)
        }

        let mediaSize = pdfPage.bounds(for: .mediaBox)
        guard mediaSize.width > 0.0, mediaSize.height > 0.0 else {
            // Degenerate case, collapsed page size.
            return .init(width: doubleMargin, height: doubleMargin)
        }

        let containerAspectRatio = withinSize.width / withinSize.height
        let mediaAspectRatio = mediaSize.width / mediaSize.height

        if containerAspectRatio >= mediaAspectRatio {
            // Container is wider, media height limits.
            return .init(
                width: withinSize.height * mediaAspectRatio + doubleMargin,
                height: withinSize.height + doubleMargin
            )
        } else {
            // Container is taller, media width limits.
            return .init(
                width: withinSize.width + doubleMargin,
                height: withinSize.width / mediaAspectRatio + doubleMargin
            )
        }
    }

    /// Sets the margin around the image, which shows selection highlight
    ///
    /// The default value is 2.0
    public var selectionMargin: CGFloat {
        get {
            horizontalMargin.constant * 0.5
        }

        set {
            let constant = 2.0 * newValue
            horizontalMargin.constant = constant
            verticalMargin.constant = constant
        }
    }

    private static let defaultThumbnailSize = CGSize(width: 100.0, height: 100.0)

    private func configure(with pdfPage: PDFPage?) {
        guard let pdfPage else {
            // Just cleanup and leave.
            imageView?.image = nil
            return
        }

        let thumbnailImage = pdfPage.thumbnail(
            of: Self.desiredSize(forPage: pdfPage, contained: desiredSize, margin: selectionMargin),
            for: .mediaBox
        )

        imageView?.image = thumbnailImage
    }
}

// MARK: - NSCollectionViewItem Overrides

extension PDFPageItem {
    override var isSelected: Bool {
        didSet {
            selectionEffect.isHidden = !isSelected
        }
    }
}

// MARK: - NSViewController Overrides

extension PDFPageItem {
    override var representedObject: Any? {
        get {
            super.representedObject
        }

        set {
            guard newValue == nil else {
                preconditionFailure("representedObject shouldn't be set directly on `PDFPageItem`")
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        selectionEffect.isEmphasized = true

        let doubleClickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(selectPage(_:)))
        doubleClickRecognizer.numberOfClicksRequired = 2
        doubleClickRecognizer.delaysPrimaryMouseButtonEvents = false // So selection also happens immediately.
        doubleClickRecognizer.delegate = self
        imageView?.addGestureRecognizer(doubleClickRecognizer)
    }
}

// MARK: - User Interaction

extension PDFPageItem {
    @objc
    private func selectPage(_: Any?) {
        guard let pdfPage else {
            return
        }

        // This is pretty coupled with `PDFPagePicker` so we'll just dig in for it.
        for next in sequence(first: self, next: \.nextResponder) {
            if let pdfPagePicker = next as? PDFPagePicker {
                pdfPagePicker.pickDoubleClickedPage(pdfPage)
                return
            }
        }
    }
}

// MARK: - NSGestureRecognizerDelegate

extension PDFPageItem: NSGestureRecognizerDelegate {
    func gestureRecognizer(
        _: NSGestureRecognizer,
        shouldBeRequiredToFailBy _: NSGestureRecognizer
    ) -> Bool {
        false
    }
}
