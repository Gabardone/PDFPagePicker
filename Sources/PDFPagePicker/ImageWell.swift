//
//  ImageWell.swift
//
//
//  Created by Óscar Morales Vivó on 2/23/23.
//

import Cocoa
import Iutilitis
import PDFKit
import UniformTypeIdentifiers

/**
 A lightweight `NSImageView` subclass that will intercept multipage pdf content and show a page picker.

 The class will request presentation of a pdf page picker down the responder chain when given multipage pdf content.
 Otherwise it works exactly as any regular instance of its superclass.
 */
open class ImageWell: NSImageView {
    @objc
    func paste(_ sender: Any?) {
        // Either `nil` or `true` mean we have to do our thing.
        guard firstResponder(ofType: ImageWellImport.self)?.imageWell(
            self,
            willImportImageFrom: .general,
            verb: .pasteVerb
        ) != false else {
            // Importer down the chain still needs to do work.
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

    override open func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard firstResponder(ofType: ImageWellImport.self)?.imageWell(
            self,
            willImportImageFrom: sender.draggingPasteboard,
            verb: .dropVerb
        ) != false else {
            // The override importer is overriding.
            return true
        }

        return super.performDragOperation(sender)
    }

    override open func concludeDragOperation(_: NSDraggingInfo?) {
        // This method intentionally left blank. For some reason `NSImageView` sets the image _again_ here, which
        // causes a glitch if we're running the pdf page picker.
    }
}
