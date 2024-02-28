//
//  PDFPagePicker.swift
//
//
//  Created by Óscar Morales Vivó on 2/11/23.
//

import Cocoa
import os
import PDFKit

public class PDFPagePicker: NSViewController {
    static let logger = Logger(subsystem: Bundle.module.bundleIdentifier!, category: "\(PDFPagePicker.self)")

    public init(pdfDocument: PDFDocument, verb: LocalizedStringResource, completion: @escaping (NSImage) -> Void) {
        self.verb = verb
        self.completion = completion
        super.init(nibName: "PDFPagePicker", bundle: .module)
        self.representedObject = pdfDocument
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Properties

    private let completion: (NSImage) -> Void

    private let verb: LocalizedStringResource

    // MARK: - IBOutlets

    @IBOutlet
    private var headerLabel: NSTextField!

    @IBOutlet
    private var collectionView: NSCollectionView!

    @IBOutlet
    private var pickPageButton: NSButton!
}

// MARK: - Actions

extension PDFPagePicker {
    func pickDoubleClickedPage(_ pdfPage: PDFPage) {
        dismissSelf()
        pickPDFPage(pdfPage)
    }

    private func pickPDFPage(_ pdfPage: PDFPage) {
        guard let selectedPageData = pdfPage.dataRepresentation else {
            Self.logger.error("Unable to extract page pdf data for pdf page \(pdfPage).")
            return
        }

        guard let pageImage = NSImage(data: selectedPageData) else {
            Self.logger.error("Unable to create image from pdf page \(pdfPage).")
            return
        }

        completion(pageImage)
    }
}

// MARK: - IBActions

extension PDFPagePicker {
    @IBAction
    private func pickPage(_: Any?) {
        pickPage()
    }

    private func pickPage() {
        dismissSelf()

        guard let selectedIndex = collectionView.selectionIndexPaths.first?.item else {
            Self.logger.error("Attempted to pick a page but no page is selected.")
            return
        }

        guard let selectedPage = pdfDocument.page(at: selectedIndex) else {
            let doc = pdfDocument
            Self.logger.error("Page at index \(selectedIndex) not found in pdf document \(doc).")
            return
        }

        pickPDFPage(selectedPage)
    }

    @IBAction
    private func cancel(_: NSButton?) {
        dismissSelf()
    }

    private func dismissSelf() {
        if let presentingViewController {
            presentingViewController.dismiss(self)
        } else {
            dismiss(self)
        }
    }
}

// MARK: - View Model

public extension PDFPagePicker {
    var pdfDocument: PDFDocument {
        guard let pdfDocument = super.representedObject as? PDFDocument else {
            preconditionFailure("PDFPagePicker.representedObject of unexpected type \(type(of: super.representedObject))")
        }

        return pdfDocument
    }
}

// MARK: - NSViewController Overrides

public extension PDFPagePicker {
    private static let itemHeight = 180.0

    private static let estimatedItemSize = CGSize(width: itemHeight / sqrt(2.0), height: itemHeight)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Finish configuring the collection view.
        collectionView.register(PDFPageItem.self, forItemWithIdentifier: PDFPageItem.identifier)

        // Configure labels.
        headerLabel.stringValue = String(localized: .labelFormat(verb: verb))
        pickPageButton.title = String(localized: .actionButtonFormat(verb: verb))
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        collectionView.reloadData()
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        // Make sure there's a selection.
        collectionView.selectItems(at: [.init(item: 0, section: 0)], scrollPosition: .centeredHorizontally)
    }
}

// MARK: - NSStandardKeyBindingResponding Overrides

public extension PDFPagePicker {
    override func doCommand(by selector: Selector) {
        if selector == #selector(insertNewline(_:)) {
            // If we got sent an enter we'd want to pick the page.
            pickPage()
        } else {
            super.doCommand(by: selector)
        }
    }
}

// MARK: - NSCollectionViewDataSource Adoption

extension PDFPagePicker: NSCollectionViewDataSource {
    public func collectionView(_: NSCollectionView, numberOfItemsInSection _: Int) -> Int {
        pdfDocument.pageCount
    }

    public func collectionView(
        _ collectionView: NSCollectionView,
        itemForRepresentedObjectAt indexPath: IndexPath
    ) -> NSCollectionViewItem {
        guard let item = collectionView.makeItem(
            withIdentifier: PDFPageItem.identifier,
            for: indexPath
        ) as? PDFPageItem else {
            return NSCollectionViewItem()
        }

        item.selectionMargin = Self.selectionMargin
        item.desiredSize = PDFPageItem.desiredSize(
            forPage: pdfDocument.page(at: indexPath.item)!,
            contained: Self.sampleSize,
            margin: Self.selectionMargin
        )
        item.pdfPage = pdfDocument.page(at: indexPath.item)

        return item
    }
}

extension PDFPagePicker: NSCollectionViewDelegate {
    public func collectionView(_: NSCollectionView, shouldSelectItemsAt indexPaths: Set<IndexPath>) -> Set<IndexPath> {
        indexPaths
    }
}

// MARK: - NSCollectionViewDelegateFlowLayout

extension PDFPagePicker: NSCollectionViewDelegateFlowLayout {
    private static let sampleSize = CGSize(width: 1000.0, height: itemHeight)

    private static let selectionMargin = 4.0

    public func collectionView(
        _: NSCollectionView,
        layout _: NSCollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> NSSize {
        guard let pdfPage = pdfDocument.page(at: indexPath.item) else {
            return .zero
        }

        return PDFPageItem.desiredSize(forPage: pdfPage, contained: Self.sampleSize, margin: Self.selectionMargin)
    }
}
