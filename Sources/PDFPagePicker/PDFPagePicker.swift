import Cocoa
import PDFKit

public class PDFPagePicker: NSViewController {
    public init() {
        super.init(nibName: "PDFPagePicker", bundle: Bundle.module)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - IBOutlets

    @IBOutlet
    private var collectionView: NSCollectionView!
}

// MARK: - View Model

extension PDFPagePicker {
    public var pdfDocument: PDFDocument? {
        get {
            super.representedObject as? PDFDocument
        }

        set {
            super.representedObject = newValue

            collectionView.reloadData()
        }
    }
}

// MARK: - NSViewController Overrides

extension PDFPagePicker {
    override public func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(PDFPageItem.self, forItemWithIdentifier: PDFPageItem.identifier)
    }

    override public var representedObject: Any? {
        get {
            return super.representedObject
        }

        set {
            preconditionFailure("representedObject shouldn't be set directly on `PDFPagePicker`")
        }
    }
}

// MARK: - NSCollectionViewDataSource Adoption

extension PDFPagePicker: NSCollectionViewDataSource {
    public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return pdfDocument?.pageCount ?? 0
    }

    public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let item = collectionView.makeItem(withIdentifier: PDFPageItem.identifier, for: indexPath) as? PDFPageItem else {
            return NSCollectionViewItem()
        }

        item.pdfPage = pdfDocument?.page(at: indexPath.item)

        return item
    }
}

// MARK: - NSCollectionViewDelegate Adoption

extension PDFPagePicker: NSCollectionViewDelegate {

}
