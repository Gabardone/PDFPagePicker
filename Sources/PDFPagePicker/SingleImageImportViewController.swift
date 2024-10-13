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
    @Published
    public var imageImport: ImageImport? {
        didSet {
            guard imageImport != oldValue else { return }

            updateUI(image: imageImport?.image)
        }
    }
}

// MARK: - IBActions

extension SingleImageImportViewController {
    @IBAction
    private func deleteImage(_: NSButton) {
        // Straightforward, so far.
        imageImport = nil
    }

    @IBAction
    private func importImage(_: NSButton) {
        guard isViewLoaded, let window = view.window else {
            return
        }

        let openPanel = NSOpenPanel.singleImageImporter()
        openPanel.beginSheetModal(for: window) { [weak self] modalResponse in
            guard let self else { return }
            switch modalResponse {
            case .OK:
                if let imageFileURL = openPanel.urls.first {
                    Task {
                        if let imageImport = try await self.importImageFrom(fileURL: imageFileURL, verb: .importVerb) {
                            self.imageImport = imageImport
                        }
                    }
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

        updateUI(image: imageImport?.image)
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

// MARK: - NSOpenSavePanelDelegate Adoption

// extension SingleImageImportViewController: NSOpenSavePanelDelegate {}

// MARK: - ImageWellImport Adoption

extension SingleImageImportViewController: ImageWellImport {
    func imageWell(
        _: ImageWell,
        importImageFrom pasteboard: NSPasteboard,
        verb: LocalizedStringResource
    ) {
        Task {
            if let imageImport = try await importImageFrom(pasteboard: pasteboard, verb: verb) {
                self.imageImport = imageImport
            }
        }
    }
}
