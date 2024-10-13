//
//  ImageWell.swift
//
//
//  Created by Óscar Morales Vivó on 2/23/23.
//

import Cocoa
import Iutilitis
import os

/**
 A lightweight `NSImageView` subclass that will intercept multipage pdf content and show a page picker.

 The class will request presentation of a pdf page picker down the responder chain when given multipage pdf content.
 Otherwise it works exactly as any regular instance of its superclass.
 */
@MainActor
open class ImageWell: NSImageView {
    static let logger = Logger(
        subsystem: Bundle.module.bundleIdentifier!,
        category: "\(SingleImageImport.self)"
    )

    @objc
    func paste(_: Any?) {
        if let importer = firstResponder(ofType: ImageWellImport.self) {
            importer.imageWell(self, importImageFrom: .general, verb: .pasteVerb)
        } else {
            Self.logger.error("Unable to find an image importer (`SingleImageImport`) in the responder chain")
        }
    }

    override open func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let importer = firstResponder(ofType: ImageWellImport.self) {
            importer.imageWell(self, importImageFrom: sender.draggingPasteboard, verb: .dropVerb)
            return true
        } else {
            Self.logger.error("Unable to find an image importer (`SingleImageImport`) in the responder chain")
            return false
        }
    }

    override open func concludeDragOperation(_: NSDraggingInfo?) {
        // This method intentionally left blank. For some reason `NSImageView` sets the image _again_ here, which
        // causes a glitch if we're running the pdf page picker.
    }
}
