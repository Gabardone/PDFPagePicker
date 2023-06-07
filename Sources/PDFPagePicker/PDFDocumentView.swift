//
//  PDFDocumentView.swift
//
//
//  Created by Óscar Morales Vivó on 2/24/23.
//

import Cocoa

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
