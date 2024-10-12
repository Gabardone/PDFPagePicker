//
//  NSResponder+PDFPagePicker.swift
//
//
//  Created by Óscar Morales Vivó on 2/23/23.
//

import Cocoa
import PDFKit
import UniformTypeIdentifiers

public extension PDFDocument {
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
     - Returns `true` if the picker is being shown, `false` if there is no need to show it.
     */
    //    public func pickPDFPage(
    //        from pdfFileURL: URL,
    //        verb: LocalizedStringResource,
    //        completion: @escaping (ImageImport) -> Void
    //    ) -> Bool {
    //        // Check first if we can get a pdf document
    //        guard let pdfDocument = PDFDocument(url: pdfFileURL) else {
    //            PDFPagePicker.logger.error("File is not a pdf, or has no pages to import.")
    //            return
    //        }
    //
    //        pickPDFPage(source: .file(pdfFileURL) , pdfDocument: pdfDocument, verb: verb, completion: completion)
    //    }

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
    public func pickPDFPage(
        source: ImageImport.Source,
        verb: LocalizedStringResource,
        completion: @escaping (ImageImport) -> Void
    ) -> Bool {
        let pdfDocument: PDFDocument
        do {
            pdfDocument = try source.makePDFDocument()
        } catch {
            return false
        }

        switch pdfDocument.pageCount {
        case 0:
            // Unsure how we found an empty pdf but let's walk back into the bushes...
            PDFPagePicker.logger.error("Empty pdf file, no image to import.")
            return false

        case 1:
            // For single page documents we're kinda good already.
            guard let pdfData = pdfDocument.dataRepresentation(),
                  let image = NSImage(data: pdfData) else {
                PDFPagePicker.logger.error("Unable to create image from pdf page.")
                return false
            }

            completion(.init(source: source, image: image, type: .pdf))
            return false

        default:
            // If we got here we need to present the actual page picker.
            let pdfPagePicker = PDFPagePicker(pdfDocument: pdfDocument, verb: verb, completion: completion)
            presentPDFPagePicker(pdfPagePicker)
            return true
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

    func processSelectedImageFile(atURL imageFileURL: URL) async throws -> ImageImport? {
        // Get the file type.
        guard let typeID = try? imageFileURL.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else {
            try SingleImageImport.logger.logAndThrow(error: ProcessFileError.unableToDetermineFileType(imageFileURL))
        }

        // Make sure that the file is of a system-supported image type.
        guard let imageUTType = UTType(typeID), NSImage.imageUnfilteredTypes.contains([imageUTType.identifier]) else {
            try SingleImageImport.logger.logAndThrow(error: ProcessFileError.unsupportedImageType(typeID, imageFileURL))
        }

        switch imageUTType {
        case .pdf:
            // If it's a pdf and we need ot run the picker return.
            return await withCheckedContinuation({ continuation in
                if pickPDFPage(
                    source: .file(imageFileURL),
                    verb: .importVerb,
                    completion: { imageImport in
                        continuation.resume(returning: imageImport)
                    }
                ) {
                    return
                } else {
                    continuation.resume(returning: nil)
                }
            })

        default:
            // If we're here we have a supported file with a single image so as long as we can actually build a `NSImage`
            // off it we can return that.
            if let image = NSImage(contentsOf: imageFileURL) {
                return .init(source: .file(imageFileURL), image: image, type: imageUTType)
            } else {
                try SingleImageImport.logger.logAndThrow(error: ProcessFileError.unableToCreateImage(typeID, imageFileURL))
            }
        }
    }
}

extension NSResponder {
    /// Errors thrown by `NSResponder.processSelectedImageFile(atURL:)`
    enum ProcessFileError: Error {
        case unableToDetermineFileType(URL)
        case unsupportedImageType(String, URL)
        case unableToCreateImage(String, URL)

        var localizedDescription: String {
            switch self {
            case let .unableToDetermineFileType(imageFileURL):
                "Cannot determine type of user selected image at URL \(imageFileURL)"

            case let .unsupportedImageType(typeID, imageFileURL):
                "User selected file of unsupported image type with identifier \(typeID) at \(imageFileURL)"

            case let .unableToCreateImage(typeID, imageFileURL):
                "Unable to create image of type \(typeID) from file \(imageFileURL)"
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
    }
}
