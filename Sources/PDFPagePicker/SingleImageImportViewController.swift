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
    required init?(coder: NSCoder) {
        fatalError("\(type(of: Self.self)) does not support NSCoding")
    }

    // MARK: - IBOutlets

    @IBOutlet private var imageWell: NSImageView!

    @IBOutlet private var deleteButton: NSButton!

    @IBOutlet private var dropImageLabel: NSTextField!

    // MARK: - Stored Properties

    /// Can be set for initialization, can be subscribed to for updates or checked for current value.
    @Published
    public var image: NSImage? {
        didSet {
            guard image != oldValue else {
                return
            }

            imageWell.image = image

            let hasImage = image != nil
            deleteButton?.isHidden = !hasImage
            dropImageLabel?.isHidden = hasImage
        }
    }

    private var subscriptions = [AnyCancellable]()
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

// MARK: - UI Management

extension SingleImageImportViewController {
    private func updateAccessoryControls() {

    }
}

// MARK: - NSViewController Overrides

extension SingleImageImportViewController {
    public override func viewDidLoad() {
        super.viewDidLoad()

        // Hide the button when there is no image.
        let imagePublisher = imageWell.publisher(for: \.image)

        // Update the image property when the image well is updated.
        // Should short-circuit due to equality when the property itself is set.
        imagePublisher
            .sink { [weak self] image in
                self?.image = image
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
            pickPDFPage(from: imageFileURL, verb: NSLocalizedString("IMPORT_VERB", value: "Import", comment: "Import verb for pdf page picker display when opening a file")) { [weak self] image in
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
