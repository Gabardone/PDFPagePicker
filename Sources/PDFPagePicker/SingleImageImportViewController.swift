//
//  SingleImageImportViewController.swift
//  PDFPagePickerTestApp
//
//  Created by Óscar Morales Vivó on 2/11/23.
//

import Cocoa
import Combine
import os
import PDFKit
import UniformTypeIdentifiers

public class SingleImageImportViewController: NSViewController {
    private static let logger = Logger(subsystem: Bundle.module.bundleIdentifier!, category: "\(SingleImageImportViewController.self)")

    public init() {
        super.init(nibName: "SingleImageImportViewController", bundle: .module)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("\(type(of: Self.self)) does not support NSCoding")
    }

    // MARK: - IBOutlets

    @IBOutlet private var imageWell: NSImageView!

    @IBOutlet private var deleteButton: NSButton!

    @IBOutlet private var dropImageLabel: NSTextField!

    // MARK: - Stored Properties

    /// Can be set for initialization, can be subscribed to for updates or checked for current value.
    public var image: NSImage? {
        get {
            imageSubject.value
        }

        set {
            guard imageSubject.value != newValue else {
                return
            }

            imageSubject.send(newValue)

            updateUI(image: newValue)
        }
    }

    public var imageUpdatePublisher: some Publisher<NSImage?, Never> {
        imageSubject
    }

    private var imageSubject = CurrentValueSubject<NSImage?, Never>(nil)

    private var subscriptions = [AnyCancellable]()
}

// MARK: - IBActions

extension SingleImageImportViewController {
    @IBAction
    private func deleteImage(_: NSButton) {
        // Straightforward, so far.
        imageWell.image = nil
    }

    @IBAction
    private func importImage(_: NSButton) {
        guard isViewLoaded, let window = view.window else {
            return
        }

        let openPanel = setupOpenPanel()
        openPanel.beginSheetModal(for: window) { [weak self] modalResponse in
            guard let self else { return }
            switch modalResponse {
            case .OK:
                if let imageFileURL = openPanel.urls.first {
                    self.processSelectedImageFile(atURL: imageFileURL)
                }

            default:
                // Dunno.
                break
            }
        }
    }
}

// MARK: - NSViewController Overrides

public extension SingleImageImportViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        updateUI(image: image)

        imageWell.publisher(for: \.image)
            .removeDuplicates()
            .sink { [weak self] image in
                self?.image = image
            }
            .store(in: &subscriptions)
    }
}

// MARK: - UI Utilities

extension SingleImageImportViewController {
    private func updateUI(image: NSImage?) {
        imageWell?.image = image

        let hasImage = image != nil
        deleteButton?.isHidden = !hasImage
        dropImageLabel?.isHidden = hasImage
    }
}

// MARK: - Import Utilities

extension SingleImageImportViewController {
    private func setupOpenPanel() -> NSOpenPanel {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        // For now let's go with safe types: png, jpg & pdf (the latter will just grab page 1).
        openPanel.allowedContentTypes = [.png, .jpeg, .pdf]
        openPanel.delegate = self

        return openPanel
    }

    private func processSelectedImageFile(atURL imageFileURL: URL) {
        guard let typeID = try? imageFileURL.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else {
            Self.logger.error("Cannot determinte type of user selected image at URL \(imageFileURL)")
            return
        }

        guard let imageUTType = UTType(typeID) else {
            Self.logger.error("User selected file of unsupported image type with identifier \(typeID) at \(imageFileURL)")
            return
        }

        switch imageUTType {
        case .pdf:
            // We may need to run the pdf page picker to extract the image for the page we actually want.
            pickPDFPage(from: imageFileURL, verb: .importVerb) { [weak self] image in
                self?.imageWell.image = image
            }

        case .jpeg, .png:
            if let image = NSImage(contentsOf: imageFileURL) {
                imageWell.image = image
            }

        default:
            Self.logger.error("User selected file of unsupported image type with identifier \(typeID) at \(imageFileURL)")
        }
    }
}

// MARK: - NSOpenSavePanelDelegate Adoption

extension SingleImageImportViewController: NSOpenSavePanelDelegate {}

// MARK: - ImageWellImport Adoption

extension SingleImageImportViewController: ImageWellImport {
    func imageWell(
        _: ImageWell,
        willImportImageFrom pasteboard: NSPasteboard,
        verb: LocalizedStringResource
    ) -> Bool {
        // Check if there's direct pdf content.
        if pasteboard.availableType(from: [.pdf]) != nil,
           let pdfData = pasteboard.data(forType: .pdf),
           let pdfDocument = PDFDocument(data: pdfData) {
            pickPDFPage(from: pdfDocument, verb: verb) { [weak self] image in
                self?.image = image
            }
            return true
        }

        // If it's a file try to see if we can extract an image from it (right now it'll just paste... the icon?)
        if pasteboard.availableType(from: [.fileURL]) != nil,
           let fileURL = pasteboard.readObjects(
               forClasses: [NSURL.self],
               options: [.urlReadingFileURLsOnly: NSNumber(true)]
           )?.first as? URL,
           let typeID = try? fileURL.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
           let utType = UTType(typeID) {
            if utType == .pdf {
                // It's a pdf!. Run the pdf page picker if needed.
                pickPDFPage(from: fileURL, verb: verb) { [weak self] image in
                    self?.image = image
                }
                return true
            } else if NSImage.imageTypes.contains(utType.identifier), let image = NSImage(contentsOf: fileURL) {
                // A supported image file, let's just paste that.
                // For some reason the system is pasting the icon in the well (OS bug? This used to work...).
                self.image = image
                return true
            }
        }

        return false
    }
}
