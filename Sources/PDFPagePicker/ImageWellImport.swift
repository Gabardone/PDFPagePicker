//
//  ImageWellImport.swift
//
//
//  Created by Óscar Morales Vivó on 2/28/24.
//

import Cocoa

/**
 A responder chain protocol to adopt by responders that know how to manage an image well's importing.

 It doesn't require inheritance from `NSResponder` as for historical reasons some of the objects in the responder chain
 won't inherit from that class, but in general it should be adopted by the components down the chain that manage an
 `ImageWell`, usually a `NSViewController` or something with a similar purpose.
 */
@MainActor
protocol ImageWellImport {
    /**
     Responder chain delegate for the component responsible to manage the import of images into the image well.

     A responder that implements this method will have it called whenever the `ImageWell` is requested to paste an image
     into it, whether through drag & drop or a paste command. The receiver can initiate any additional processing needed
     i.e. displaying the pdf page picker sheet.
     - Parameters:
       - imageWell: The image well that wants to import the pasteboard contents.
       - pasteboard: The pasteboard containing the data to import.
       - verb: The verb that should be displayed for undo menu labeling and other descriptions.
     */
    func imageWell(
        _ imageWell: ImageWell,
        importImageFrom pasteboard: NSPasteboard,
        verb: LocalizedStringResource
    )
}
