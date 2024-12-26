//
//  NSResponder+PDFPagePicker.swift
//
//
//  Created by Óscar Morales Vivó on 2/23/23.
//

import Cocoa
import os
import PDFKit
import UniformTypeIdentifiers

private extension PDFDocument {
    enum InitializationError: Error {
        case dataFailure(Data)
        case fileFailure(URL)
    }
}

private extension ImageImport.Source {
    func makePDFDocument() throws -> PDFDocument {
        let pdfDocument: PDFDocument
        switch self {
        case let .data(data):
            if let document = PDFDocument(data: data) {
                pdfDocument = document
            } else {
                throw PDFDocument.InitializationError.dataFailure(data)
            }

        case let .file(fileURL):
            if let document = PDFDocument(url: fileURL) {
                pdfDocument = document
            } else {
                throw PDFDocument.InitializationError.fileFailure(fileURL)
            }
        }

        return pdfDocument
    }
}

extension NSResponder {
    /**
     Returns a sequence containing the responder chain starting at the calling instance.

     Keep in mind that AppKit responder management may also look into non-`NSResponder` objects like window/app
     delegates.
     - Returns A sequence starting with `self` whose elements form the responder chain from `self`.
     */
    func responderChain() -> some Sequence<NSResponder> {
        sequence(first: self, next: \.nextResponder)
    }

    /**
     Finds the next element in the responder chain of the given type, including oneself (call on `nextResponder` if you
     want to skip further down in the chain).
     - Parameter type: The type we're looking for. Can be either an actual class type (i.e. look for the closest
     ancestor of a containing view or view controller type). Or a protocol (useful for Swift-friendly responder chain
     action management).
     - Returns The closest responder down the chain of the requested type, or `nil` if none were found.
     */
    @MainActor public func firstResponder<T>(ofType _: T.Type) -> T? {
        responderChain().lazy.compactMap { responder in
            responder as? T
        }.first
    }
}

extension NSResponder {
    /**
     Determines whether the page picker needs to be presented and does so if that's the case.

     The method does all necessary validation before presenting the pdf page picker. For example if the pdf only has
     one page it will return that as the image.

     Presentation and behavior on finalization are configurable through behavior parameters.
     - Parameter source: Where the pdf came from, since we'll want to pass that along.
     - Parameter verb: The action that will be performed with the selected page. Examples include "Import" or "Copy".
     It will show both in the header label and the selection button.
     - Parameter completion: A block called once we have an image for the selected pdf page with the image and the
     data backing it.
     - Returns: `true` if the picker is being shown, `false` if there is no need to show it.
     */
    private func pickPDFPage(source: ImageImport.Source, verb: LocalizedStringResource) async throws -> ImageImport {
        let pdfDocument = try source.makePDFDocument()

        switch pdfDocument.pageCount {
        case 0:
            // Unsure how we found an empty pdf but let's walk back into the bushes...
            try Logger.pdfPagePicker.logAndThrow(error: ImageImportError.emptyPDF(pdfDocument))

        case 1:
            // For single page documents we're kinda good already.
            guard let pdfData = pdfDocument.dataRepresentation(),
                  let image = NSImage(data: pdfData) else {
                try Logger.pdfPagePicker.logAndThrow(
                    error: ImageImportError.unableToCreateImageFromPage(0, pdfDocument)
                )
            }

            return .init(source: source, image: image, type: .pdf)

        default:
            // If we got here we need to present the actual page picker.
            return try await withCheckedThrowingContinuation { continuation in
                let pdfPagePicker = PDFPagePicker(pdfDocument: pdfDocument, verb: verb) { imageImport in
                    switch imageImport {
                    case let .success(imageImport):
                        continuation.resume(returning: imageImport)

                    case .cancel:
                        continuation.resume(throwing: CancellationError())

                    case let .error(error):
                        continuation.resume(throwing: error)
                    }
                }
                presentPDFPagePicker(pdfPagePicker)
            }
        }
    }

    /**
     Presents a pdf page picker.

     This method should not be called directly (instead using one of the `pickPDFPage` variants), but it can be
     overwritten (allowed, as an `@objc` method) to customize the presentation of the picker when it needs to appear.

     If nothing in the responder chain does the presentation, a modal dialog will be shown.
     - Parameter pagePicker: The page picker view controller that should be presented for the user to pick a page. It
     is already fully configured.
     */
    @objc open func presentPDFPagePicker(_ pagePicker: PDFPagePicker) {
        // By default it's down the responder chain.
        if let nextResponder {
            nextResponder.presentPDFPagePicker(pagePicker)
        } else {
            // Dunno, run modal.
            let panel = NSWindow(contentViewController: pagePicker)
            NSApplication.shared.runModal(for: panel)
        }
    }

    func importImageFrom(pasteboard: NSPasteboard, verb: LocalizedStringResource) async throws -> ImageImport? {
        if pasteboard.availableType(from: [.fileURL]) != nil,
           let fileURL = pasteboard.readObjects(
               forClasses: [NSURL.self],
               options: [.urlReadingFileURLsOnly: NSNumber(true)]
           )?.first as? URL {
            // If there's a file URL we redirect there.
            return try await importImageFrom(fileURL: fileURL, verb: verb)
        } else if pasteboard.availableType(from: [.pdf]) != nil {
            // Let's check first if we have pdf data.
            guard let pdfData = pasteboard.data(forType: .pdf) else {
                throw ImageImportError.unableToGetPDFDataFromPasteboard(pasteboard)
            }

            return try await pickPDFPage(source: .data(pdfData), verb: verb)
        } else {
            // Try to find the best supported image type.
            let supportedTypes = NSImage.imageTypes
            for type in pasteboard.types ?? [] {
                if supportedTypes.contains(type.rawValue),
                   let utType = UTType(type.rawValue),
                   let imageData = pasteboard.data(forType: type),
                   let image = NSImage(data: imageData) {
                    return .init(source: .data(imageData), image: image, type: utType)
                }
            }

            throw ImageImportError.noSupportedImageTypeFound(pasteboard)
        }
    }

    func importImageFrom(fileURL: URL, verb: LocalizedStringResource) async throws -> ImageImport? {
        // Get the file type.
        guard let typeID = try? fileURL.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else {
            try SingleImageImport.logger.logAndThrow(error: ImageImportError.unableToDetermineFileType(fileURL))
        }

        // Make sure that the file is of a system-supported image type.
        guard let imageUTType = UTType(typeID), NSImage.imageUnfilteredTypes.contains([imageUTType.identifier]) else {
            try SingleImageImport.logger.logAndThrow(error: ImageImportError.unsupportedImageType(typeID, fileURL))
        }

        switch imageUTType {
        case .pdf:
            // If it's a pdf and we need ot run the picker return.
            return try await pickPDFPage(source: .file(fileURL), verb: .importVerb)

        default:
            // If we're here we have a supported file with a single image so as long as we can actually build a
            // `NSImage` off it we can return that.
            if let image = NSImage(contentsOf: fileURL) {
                return .init(source: .file(fileURL), image: image, type: imageUTType)
            } else {
                try SingleImageImport.logger.logAndThrow(
                    error: ImageImportError.unableToCreateImage(typeID, fileURL)
                )
            }
        }
    }
}

extension NSResponder {
    /// Errors thrown by `NSResponder.processSelectedImageFile(atURL:)`
    enum ImageImportError: Error, @unchecked Sendable {
        case unableToDetermineFileType(URL)
        case unsupportedImageType(String, URL)
        case unableToCreateImage(String, URL)

        case emptyPDF(PDFDocument)
        case unableToCreateImageFromPage(Int, PDFDocument)

        case unableToGetPDFDataFromPasteboard(NSPasteboard)
        case noSupportedImageTypeFound(NSPasteboard)

        var localizedDescription: String {
            switch self {
            case let .unableToDetermineFileType(imageFileURL):
                "Cannot determine type of user selected image at URL \(imageFileURL)"

            case let .unsupportedImageType(typeID, imageFileURL):
                "User selected file of unsupported image type with identifier \(typeID) at \(imageFileURL)"

            case let .unableToCreateImage(typeID, imageFileURL):
                "Unable to create image of type \(typeID) from file \(imageFileURL)"

            case let .emptyPDF(pdfDocument):
                "Impossible to create image from empty pdf document \(pdfDocument)."

            case let .unableToCreateImageFromPage(pageNumber, pdfDocument):
                "Unable to create image from page \(pageNumber) of pdf document \(pdfDocument)."

            case let .unableToGetPDFDataFromPasteboard(pasteboard):
                "Unable to get pdf data from pasteboard \(pasteboard)."

            case let .noSupportedImageTypeFound(pasteboard):
                "No supported image type found in pasteboard \(pasteboard)."
            }
        }
    }
}

extension NSViewController {
    /**
     The default `NSViewController` implementation of this method presents a sheet.
     */
    @objc override open func presentPDFPagePicker(_ pagePicker: PDFPagePicker) {
        presentAsSheet(pagePicker)
        NSApplication.shared.activate(ignoringOtherApps: true) // In case this happened due to drop.
    }
}
