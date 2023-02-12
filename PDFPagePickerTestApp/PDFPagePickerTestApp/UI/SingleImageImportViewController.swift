//
//  SingleImageImportViewController.swift
//  PDFPagePickerTestApp
//
//  Created by Óscar Morales Vivó on 2/11/23.
//

import AutoLayoutHelpers
import Cocoa
import Combine
import os
import PDFKit
import PDFPagePicker
import UniformTypeIdentifiers

class SingleImageImportViewController: NSViewController {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "\(SingleImageImportViewController.self)")

    // MARK: - IBOutlets

    @IBOutlet private var imageWell: NSImageView!

    @IBOutlet private var deleteButton: NSButton!

    @IBOutlet private var dropImageLabel: NSTextField!

    // MARK: - Properties

    private var subscriptions = [AnyCancellable]()

    private lazy var pdfPagePicker = PDFPagePicker()
}

// MARK: - IBActions

extension SingleImageImportViewController {
    @IBAction
    private func deleteImage(_ sender: NSButton) {
        // Straightforward, so far.
        imageWell.image = nil
    }

    @IBAction
    private func importImage(_ sender: NSButton) {
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

extension SingleImageImportViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Hide the button when there is no image.
        imageWell.publisher(for: \.image)
            .map { image in
                image != nil
            }
            .sink { [deleteButton, dropImageLabel] hasImage in
                deleteButton?.isHidden = !hasImage
                dropImageLabel?.isHidden = hasImage
            }
            .store(in: &subscriptions)
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

        openPanel.accessoryView = pdfPagePicker.view

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
            // TEST: Grab the last page (will need to build a picker later).
            guard let pdfDocument = PDFDocument(url: imageFileURL),
                  let lastPage = pdfDocument.page(at: pdfDocument.pageCount - 1) else {
                Self.logger.error("Unable to fetch last page of document.")
                return
            }

            guard let pageDocument = lastPage.dataRepresentation else {
                Self.logger.error("Unable to create document out of page.")
                return
            }

            if let image = NSImage(data: pageDocument) {
                imageWell.image = image
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

extension SingleImageImportViewController: NSOpenSavePanelDelegate {
    func panelSelectionDidChange(_ sender: Any?) {
        guard let openPanel = sender as? NSOpenPanel else {
            return
        }

        guard let imageFileURL = openPanel.url else {
            openPanel.isAccessoryViewDisclosed = false
            pdfPagePicker.pdfDocument = nil
            return
        }

        guard let typeID = try? imageFileURL.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else {
            Self.logger.error("Cannot determinte type of user selected image at URL \(imageFileURL)")
            return
        }

        guard let imageUTType = UTType(typeID) else {
            Self.logger.error("User selected file of unsupported image type with identifier \(typeID) at \(imageFileURL)")
            return
        }

        let isPDF = imageUTType == .pdf
        openPanel.isAccessoryViewDisclosed = isPDF
        pdfPagePicker.pdfDocument = isPDF ? PDFDocument(url: imageFileURL) : nil
    }
}
