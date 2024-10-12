//
//  ImageImport.swift
//
//
//  Created by Óscar Morales Vivó on 3/24/24.
//

import Cocoa
import UniformTypeIdentifiers

/// Encapsulates all the data of an image import, not just the image itself.
///
/// The receiver can use the type and source to more optimally store and manage the received image.
public struct ImageImport: Sendable {
    public init(source: Source, image: NSImage, type: UTType) {
        self.source = source
        self.image = image
        self.type = type
    }

    /// The actual image as a framework image. Use for immediate display or ignore if the source is what you care for.
    ///
    /// The image is not meant to be modified. You will break the `Sendable` contract if you do.
    nonisolated(unsafe) public var image: NSImage

    /// The source of the image. See the type's documentation for options.
    public var source: Source

    /// The type of the image.
    public var type: UTType
}

extension ImageImport {
    /// Describes where the type of sourcing of the image and stores the associated information for the source.
    public enum Source {
        /// The image came from a file. The associated URL should be a `file://` url that points to it.
        case file(URL)

        /// The image came from raw data, which is associated to the value.
        case data(Data)
    }
}

extension ImageImport.Source: Equatable, Sendable {}

extension ImageImport: Equatable {}
