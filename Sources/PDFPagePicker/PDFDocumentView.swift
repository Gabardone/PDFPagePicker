//
//  PDFDocumentView.swift
//
//
//  Created by Óscar Morales Vivó on 2/24/23.
//

import Cocoa

/**
 Subclass of `NSCollectionView` so we can override its keyboard management.

 Unfortunately `NSCollectionView` intercepts all keyboard activity if part of the responder chain, which really
 messes things up when i.e. presented in a dialog with a default button.

 There seems to be no better way to deal with that than subclassing and overriding.
 */
class PDFDocumentView: NSCollectionView {}

// MARK: - NSStandardKeyBindingResponding Overrides

extension PDFDocumentView {
    override func doCommand(by selector: Selector) {
        if selector == #selector(insertNewline(_:)) {
            // Sends newline down the responder chain so it can operate a default button or whatever.
            nextResponder?.doCommand(by: selector)
        } else {
            super.doCommand(by: selector)
        }
    }
}
