//
//  PDFPagePickerTestAppDelegate.swift
//  PDFPagePickerTestApp
//
//  Created by Óscar Morales Vivó on 2/7/23.
//

import Cocoa
import PDFPagePicker

@main
class PDFPagePickerTestAppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let singleImportViewController = SingleImageImportViewController()
        window.contentViewController = singleImportViewController
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
