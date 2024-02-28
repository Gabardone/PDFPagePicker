//
//  LocalizedStringResource+PDFPagePicker.swift
//
//
//  Created by Óscar Morales Vivó on 2/21/24.
//

import Foundation

extension LocalizedStringResource.BundleDescription {
    static func bundle(_ bundle: Bundle) -> Self {
        .atURL(bundle.bundleURL)
    }
}

extension LocalizedStringResource {
    static var dropVerb: LocalizedStringResource {
        .init(
            #function,
            defaultValue: "Drop",
            bundle: .bundle(.module),
            comment: "Drop verb string for button title and other control duty"
        )
    }

    static var importVerb: LocalizedStringResource {
        .init(
            #function,
            defaultValue: "Import",
            bundle: .bundle(.module),
            comment: "Import verb string for button title and other control duty"
        )
    }

    static var pasteVerb: LocalizedStringResource {
        .init(
            #function,
            defaultValue: "Paste",
            bundle: .bundle(.module),
            comment: "Paste verb string for button title and other control duty"
        )
    }

    static func actionButtonFormat(verb: LocalizedStringResource) -> LocalizedStringResource {
        .init(
            #function,
            defaultValue: "\(verb) Selected",
            bundle: .bundle(.module),
            comment: "Format string for the default button in the page picker"
        )
    }

    static func labelFormat(verb: LocalizedStringResource) -> LocalizedStringResource {
        .init(
            #function,
            defaultValue: "Select the Page to \(verb)",
            bundle: .bundle(.module),
            comment: "Format string for the header label in the page picker"
        )
    }
}
