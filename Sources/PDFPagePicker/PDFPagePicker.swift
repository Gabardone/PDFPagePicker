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
    enum PickerResult {
        case success(ImageImport)
        case cancel
        case error(Error)
    }

    enum PickerError: Error, @unchecked Sendable {
        case unableToExtractPageData(PDFPage)
        case unableToCreateImageFromPDFPage(PDFPage)
        case noPageSelection
        case noPageFoundAtIndex(Int, PDFDocument)

        var localizedDescription: String {
            switch self {
            case let .unableToExtractPageData(pdfPage):
                "Unable to extract page pdf data for pdf page \(pdfPage)."

            case let .unableToCreateImageFromPDFPage(pdfPage):
                "Unable to create image from pdf page \(pdfPage)."

            case .noPageSelection:
                "Attempted to pick a page but no page is selected."

            case let .noPageFoundAtIndex(pageIndex, pdfDocument):
                "Page at index \(pageIndex) not found in pdf document \(pdfDocument)."
            }
        }
    }

    typealias Completion = (PickerResult) -> Void

    static let logger = Logger(subsystem: Bundle.module.bundleIdentifier!, category: "\(PDFPagePicker.self)")

    init(pdfDocument: PDFDocument, verb: LocalizedStringResource, completion: @escaping Completion) {
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

    private let completion: Completion

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
        pickPDFPage(pdfPage)
    }

    private func pickPDFPage(_ pdfPage: PDFPage) {
        dismissSelf(result: {
            guard let selectedPageData = pdfPage.dataRepresentation else {
                return .error(PickerError.unableToExtractPageData(pdfPage))
            }

            guard let pageImage = NSImage(data: selectedPageData) else {
                return .error(PickerError.unableToCreateImageFromPDFPage(pdfPage))
            }

            return .success(.init(source: .data(selectedPageData), image: pageImage, type: .pdf))
        }())
    }
}

// MARK: - IBActions

extension PDFPagePicker {
    @IBAction
    private func pickPage(_: Any?) {
        pickPage()
    }

    private func pickPage() {
        guard let selectedIndex = collectionView.selectionIndexPaths.first?.item else {
            dismissSelf(result: .error(PickerError.noPageSelection))
            return
        }

        guard let selectedPage = pdfDocument.page(at: selectedIndex) else {
            dismissSelf(result: .error(PickerError.noPageFoundAtIndex(selectedIndex, pdfDocument)))
            return
        }

        pickPDFPage(selectedPage)
    }

    @IBAction
    private func cancel(_: NSButton?) {
        dismissSelf(result: .cancel)
    }

    private func dismissSelf(result: PickerResult) {
        completion(result)
        if let presentingViewController {
            presentingViewController.dismiss(self)
        } else {
            dismiss(self)
        }
    }
}

// MARK: - View Model

private extension PDFPagePicker {
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
