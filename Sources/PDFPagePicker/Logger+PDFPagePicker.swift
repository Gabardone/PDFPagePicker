//
//  Logger+PDFPagePicker.swift
//
//
//  Created by Óscar Morales Vivó on 4/24/24.
//

import Foundation
import os

extension Logger {
    /// Generic module logger for use when no more specific one is available.
    static let pdfPagePicker = Self(
        subsystem: Bundle.module.bundleIdentifier!,
        category: "PDFPagePicker"
    )

    /// Logs an error and then rethrows it.
    ///
    /// This utility makes logging and throwing a one liner, otherwise folks keep forgetting to log the errors.
    /// - Parameter error: The error to be logged, then thrown.
    func logAndThrow(error: Error) throws -> Never {
        self.error("Error: \(error)")
        throw error
    }
}
