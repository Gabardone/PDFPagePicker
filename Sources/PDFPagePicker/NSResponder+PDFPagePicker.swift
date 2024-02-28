//
//  NSResponder+PDFPagePicker.swift
//
//
//  Created by Óscar Morales Vivó on 2/23/23.
//

import Cocoa
import PDFKit

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
     */
    public func pickPDFPage(
        from pdfFileURL: URL,
        verb: LocalizedStringResource,
        completion: @escaping (NSImage) -> Void
    ) {
        // Check first if we can get a pdf document
        guard let pdfDocument = PDFDocument(url: pdfFileURL) else {
            PDFPagePicker.logger.error("File is not a pdf, or has no pages to import.")
            return
        }

        pickPDFPage(from: pdfDocument, verb: verb, completion: completion)
    }

    /**
     Determines whether the page picker needs to be presented and does so if that's the case.

     The method does all necessary validation before presenting the pdf page picker. For example if the pdf only has
     one page it will return that as the image.

     Presentation and behavior on finalization are configurable through behavior parameters.
     - Parameter pdfDocument: The pdf document we want to pick a page from.
     - Parameter verb: The action that will be performed with the selected page. Examples include "Import" or "Copy".
     It will show both in the header label and the selection button.
     - Parameter present: A block that gets passed the pdf page picker view controller so it can be presented in
     whatever way makes the more sense fo the context.
     - Parameter completion: A block called once we have an image for the selected pdf page.
     */
    public func pickPDFPage(
        from pdfDocument: PDFDocument,
        verb: LocalizedStringResource,
        completion: @escaping (NSImage) -> Void
    ) {
        switch pdfDocument.pageCount {
        case 0:
            // Unsure how we found an empty pdf but let's walk back into the bushes...
            PDFPagePicker.logger.error("Empty pdf file, no image to import.")
            return

        case 1:
            // For single page documents we're kinda good already.
            guard let pdfData = pdfDocument.dataRepresentation(),
                  let image = NSImage(data: pdfData) else {
                PDFPagePicker.logger.error("Unable to create image from pdf page.")
                return
            }

            completion(image)
            return

        default:
            // If we got here we need to present the actual page picker.
            let pdfPagePicker = PDFPagePicker(pdfDocument: pdfDocument, verb: verb, completion: completion)
            presentPDFPagePicker(pdfPagePicker)
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
}

extension NSViewController {
    /**
     The default `NSViewController` implementation of this method presents a sheet.
     */
    @objc override open func presentPDFPagePicker(_ pagePicker: PDFPagePicker) {
        presentAsSheet(pagePicker)
    }
}
