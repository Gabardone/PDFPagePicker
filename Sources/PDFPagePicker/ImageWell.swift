//
//  ImageWell.swift
//
//
//  Created by Óscar Morales Vivó on 2/23/23.
//

import Cocoa
import PDFKit
import UniformTypeIdentifiers

/**
 A lightweight `NSImageView` subclass that will intercept multipage pdf content and show a page picker.

 The class will request presentation of a pdf page picker down the responder chain when given multipage pdf content.
 Otherwise it works exactly as any regular instance of its superclass.
 */
open class ImageWell: NSImageView {
    private static let pasteVerb = NSLocalizedString(
        "PASTE_VERB",
        bundle: .module,
        value: "Paste",
        comment: "Paste verb for pdf pagepicker display when pasting pdf content"
    )

    @objc
    func paste(_ sender: Any?) {
        if overrideImportImageFrom(pasteboard: NSPasteboard.general, verb: Self.pasteVerb) {
            // The override importer is overriding.
            return
        }

        // If the above didn't work out, call super. In a rather convoluted way because it's implemented in the
        // superclass but not visibly declared where the Swift compiler can see it.
        let pasteSelector = Selector(#function)
        if let superImp = class_getMethodImplementation(Self.superclass().self, pasteSelector) {
            typealias ClosureType = @convention(c) (AnyObject, Selector, Any?) -> Void
            let superCaller = unsafeBitCast(superImp, to: ClosureType.self)
            superCaller(self, pasteSelector, sender)
        }
    }

    private static let dropVerb = NSLocalizedString(
        "DROP_VERB",
        bundle: .module,
        value: "Drop",
        comment: "Drop verb for pdf pagepicker display when dropping pdf content"
    )

    override open func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if overrideImportImageFrom(pasteboard: sender.draggingPasteboard, verb: Self.dropVerb) {
            // The override importer is overriding.
            return true
        }

        return super.performDragOperation(sender)
    }

    override open func concludeDragOperation(_: NSDraggingInfo?) {
        // This method intentionally left blank. For some reason `NSImageView` sets the image _again_ here, which
        // causes a glitch if we're running the pdf page picker.
    }

    private func overrideImportImageFrom(pasteboard: NSPasteboard, verb: String) -> Bool {
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
