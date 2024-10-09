//
//  Logger+PDFPagePicker.swift
//
//
//  Created by Óscar Morales Vivó on 4/24/24.
//

import Foundation
import os

extension Logger {
    func logAndThrow(error: Error) throws -> Never {
        self.error("Error: \(error)")
        throw error
    }
}
