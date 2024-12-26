//
//  SingleImageImport.swift
//
//
//  Created by Óscar Morales Vivó on 4/13/24.
//

import Cocoa
import os
import UniformTypeIdentifiers

public extension NSResponder {
    /**
     Starts a single image import flow.

     The default implementation will dig down the responder chain. Overrides at the window and app levels will present
     sheets or modal dialogs correspondingly.
     - Parameter types: The `UTType` types of images that can be imported. If nil, will allow for any type present in
     `NSImage.imageUnfilteredTypes`
     - Returns An image import `struct` if successful, or `nil` if no import happened due to user cancellation or other
     error.
     */
    func beginSingleImageFileImport(types: Set<UTType>? = nil) async throws -> ImageImport? {
        try await firstResponder(ofType: SingleImageImport.Importer.self)?.runSingleImageFileImportFlow(types: types)
    }
}

/// Namespace `enum` for single image import functionality that uses the pdf page picker when needed.
enum SingleImageImport {
    enum Result {
        case imported(ImageImport)
        case canceled
        case error(Error)
    }

    static let logger = Logger(
        subsystem: Bundle.module.bundleIdentifier!,
        category: "\(SingleImageImport.self)"
    )

    @MainActor
    protocol Importer {
        func runSingleImageFileImportFlow(types: Set<UTType>?) async throws -> ImageImport?
    }
}

extension NSWindow: SingleImageImport.Importer {
    func runSingleImageFileImportFlow(
        types: Set<UTType>? = nil
    ) async throws -> ImageImport? {
        try await withCheckedThrowingContinuation { continuation in
            let openPanel = NSOpenPanel.singleImageImporter(types: types)
            openPanel.beginSheetModal(for: self) { modalResponse in
                switch modalResponse {
                case .OK:
                    if let imageFileURL = openPanel.urls.first {
                        Task {
                            try await self.importImageFrom(fileURL: imageFileURL, verb: .importVerb)
                        }
                    }

                default:
                    // Dunno. Assume cancelation.
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

extension NSApplication: SingleImageImport.Importer {
    func runSingleImageFileImportFlow(
        types: Set<UTType>? = nil
    ) async throws -> ImageImport? {
        try await withCheckedThrowingContinuation { continuation in
            let openPanel = NSOpenPanel.singleImageImporter(types: types)
            switch openPanel.runModal() {
            case .OK:
                if let imageFileURL = openPanel.urls.first {
                    Task {
                        try await self.importImageFrom(fileURL: imageFileURL, verb: .importVerb)
                    }
                }

            default:
                // Dunno. Assume cancelation.
                continuation.resume(returning: nil)
            }
        }
    }
}

extension NSOpenPanel {
    /**
     Returns an open panel ready to open a single image for import.

     Supported types can be passed in, if none are, any system-supported image type will be allowed.
     - Parameter types: Allowed image import types.
     - Returns: A configured open panel for single image import.
     */
    static func singleImageImporter(types: Set<UTType>? = nil) -> NSOpenPanel {
        let types = types?.map(\.self) ?? NSImage.imageUnfilteredTypes.compactMap { typeID in
            UTType(typeID)
        }

        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = types

        return openPanel
    }
}
