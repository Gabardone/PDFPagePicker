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
                        try await self.processSelectedImageFile(atURL: imageFileURL)
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

//extension SingleImageImportViewController: NSOpenSavePanelDelegate {}

// MARK: - ImageWellImport Adoption

extension SingleImageImportViewController: ImageWellImport {
    func imageWell(
        _: ImageWell,
        willImportImageFrom pasteboard: NSPasteboard,
        verb: LocalizedStringResource
    ) -> Bool {
        // If there's direct pdf content and it has multiple pages we will show the pdf page picker…
        if pasteboard.availableType(from: [.pdf]) != nil {
            if let source: ImageImport.Source = {
                if pasteboard.availableType(from: [.fileURL]) != nil, let fileURL = pasteboard.readObjects(
                    forClasses: [NSURL.self],
                    options: [.urlReadingFileURLsOnly: NSNumber(true)]
                )?.first as? URL {
                    return .file(fileURL)
                } else if let data = pasteboard.data(forType: .pdf) {
                    return .data(data)
                } else {
                    return nil
                }
            }() {
                if pickPDFPage(source: source, verb: verb, completion: { [weak self] imageImport in
                    self?.imageImport = imageImport
                }) {
                    return true
                }
            }
        }

        // If it's a file try to see if we can extract an image from it (right now it'll just paste... the icon?)
        if pasteboard.availableType(from: [.fileURL]) != nil,
           let fileURL = pasteboard.readObjects(
               forClasses: [NSURL.self],
               options: [.urlReadingFileURLsOnly: NSNumber(true)]
           )?.first as? URL,
           let typeID = try? fileURL.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
           let utType = UTType(typeID) {
            if NSImage.imageTypes.contains(utType.identifier), let image = NSImage(contentsOf: fileURL) {
                // A supported image file, let's just paste that.
                // For some reason the system is pasting the icon in the well (OS bug? This used to work...).
                self.imageImport = .init(source: .file(fileURL), image: image, type: utType)
                return true
            }
        }

        // TODO: Check for data now. Not just pdf data 🤦🏽‍♂️

        return false
    }
}
