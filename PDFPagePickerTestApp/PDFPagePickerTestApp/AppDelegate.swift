//
//  AppDelegate.swift
//  PDFPagePickerTestApp
//
//  Created by Óscar Morales Vivó on 2/7/23.
//

import Cocoa
import PDFPagePicker

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        window.contentViewController = PDFPagePicker()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

