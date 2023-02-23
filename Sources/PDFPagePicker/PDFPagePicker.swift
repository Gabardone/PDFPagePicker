import Cocoa
import PDFKit
import os

extension NSViewController {
    /**
     Determines whether the page picker needs to be presented and does so if that's the case.

     The method does all necessary validation before presenting the pdf page picker. For example if the pdf only has
     one page it will return that as the image.

     Presentation and behavior on finalization are configurable through behavior parameters.
     - Parameter pdfFileURL: An URL for the pdf we want to extract a page from. If the URL isn't pointing to a valid
     pdf that the app can access the method will just log and return.
     - Parameter verb: The action that will be performed with the selected page. Examples include "Import" or "Copy".
     It will show both in the header label and the selection button.
     - Parameter present: A block that gets passed the pdf page picker view controller so it can be presented in
     whatever way makes the more sense fo the context.
     - Parameter completion: A block called once we have an image for the selected pdf page.
     */
    public func pickPDFPage(
        from pdfFileURL: URL,
        verb: String,
        present: (NSViewController) -> Void,
        completion: @escaping (NSImage) -> Void
    ) {
        // Check first if we can get a pdf document
        guard let pdfDocument = PDFDocument(url: pdfFileURL) else {
            PDFPagePicker.logger.error("File is not a pdf, or has no pages to import.")
            return
        }

        guard pdfDocument.pageCount > 0 else {
            PDFPagePicker.logger.error("Empty pdf file, no image to import.")
            return
        }

        guard pdfDocument.pageCount > 1 else {
            // Single page, just grab it.
            if let image = NSImage(contentsOf: pdfFileURL) {
                completion(image)
            }
            return
        }

        // If we got here we need to present the actual page picker.
        let pdfPagePicker = PDFPagePicker(pdfDocument: pdfDocument, verb: verb, completion: completion)
        present(pdfPagePicker)
    }
}

public class PDFPagePicker: NSViewController {
    fileprivate static let logger = Logger(subsystem: Bundle.module.bundleIdentifier!, category: "\(PDFPagePicker.self)")

    public init(pdfDocument: PDFDocument, verb: String, completion: @escaping (NSImage) -> Void) {
        self.verb = verb
        self.completion = completion
        super.init(nibName: "PDFPagePicker", bundle: .module)
        self.representedObject = pdfDocument
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Properties

    private let completion: (NSImage) -> Void

    private let verb: String

    // MARK: - IBOutlets

    @IBOutlet
    private var headerLabel: NSTextField!

    @IBOutlet
    private var collectionView: NSCollectionView!

    @IBOutlet
    private var pickPageButton: NSButton!
}

// MARK: - IBActions

extension PDFPagePicker {
    @IBAction
    private func pickPage(_ sender: NSButton?) {
        pickPage()
    }

    private func pickPage() {
        dismissSelf()

        guard let selectedIndex = collectionView.selectionIndexPaths.first?.item else {
            Self.logger.error("Attempted to pick a page but no page is selected.")
            return
        }

        guard let selectedPageData = pdfDocument.page(at: selectedIndex)?.dataRepresentation else {
            Self.logger.error("Unable to extract page pdf data for page at index \(selectedIndex).")
            return
        }

        guard let pageImage = NSImage(data: selectedPageData) else {
            Self.logger.error("Unable to create image from pdf page at index \(selectedIndex).")
            return
        }

        completion(pageImage)
    }

    @IBAction
    private func cancel(_ sender: NSButton?) {
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

extension PDFPagePicker {
    public var pdfDocument: PDFDocument {
        super.representedObject as! PDFDocument
    }
}

// MARK: - NSViewController Overrides

extension PDFPagePicker {
    private static let itemHeight = 180.0

    private static let estimatedItemSize = CGSize(width: itemHeight / sqrt(2.0), height: itemHeight)

    override public func viewDidLoad() {
        super.viewDidLoad()

        // Finish configuring the collection view.
        collectionView.register(PDFPageItem.self, forItemWithIdentifier: PDFPageItem.identifier)

        // Configure labels.
        let labelFormat = NSLocalizedString("LABEL_FORMAT", tableName: "PDFPagePickerLocalizable", bundle: .module, value: "Select the Page to %@:", comment: "Format string for the header label in the page picker")
        headerLabel.stringValue = .localizedStringWithFormat(labelFormat, verb)

        let buttonFormat = NSLocalizedString("BUTTON_FORMAT", tableName: "PDFPagePickerLocalizable", bundle: .module, value: "%@ Selected", comment: "Format string for the default button in the page picker")
        pickPageButton.title = .localizedStringWithFormat(buttonFormat, verb)
    }

    override public func viewWillAppear() {
        super.viewWillAppear()

        collectionView.reloadData()
    }

    override public func viewDidAppear() {
        super.viewDidAppear()

        // Make sure there's a selection.
        collectionView.selectItems(at: [.init(item: 0, section: 0)], scrollPosition: .centeredHorizontally)
    }
}

// MARK: - NSCollectionViewDataSource Adoption

extension PDFPagePicker: NSCollectionViewDataSource {
    public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return pdfDocument.pageCount
    }

    public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let item = collectionView.makeItem(withIdentifier: PDFPageItem.identifier, for: indexPath) as? PDFPageItem else {
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

// MARK: - NSCollectionViewDelegateFlowLayout

extension PDFPagePicker: NSCollectionViewDelegateFlowLayout {
    static private let sampleSize = CGSize(width: 1000.0, height: itemHeight)

    static private let selectionMargin = 4.0

    public func collectionView(
        _ collectionView: NSCollectionView,
        layout collectionViewLayout: NSCollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> NSSize {
        guard let pdfPage = pdfDocument.page(at: indexPath.item) else {
            return .zero
        }

        return PDFPageItem.desiredSize(forPage: pdfPage, contained: Self.sampleSize, margin: Self.selectionMargin)
    }
}
