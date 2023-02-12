//
//  SingleImageImportViewController.swift
//  PDFPagePickerTestApp
//
//  Created by Óscar Morales Vivó on 2/11/23.
//

import Cocoa
import Combine

class SingleImageImportViewController: NSViewController {

    // MARK: - IBOutlets

    @IBOutlet private var imageWell: NSImageView!

    @IBOutlet private var deleteButton: NSButton!

    @IBOutlet private var dropImageLabel: NSTextField!

    // MARK: - Properties

    private var subscriptions = [AnyCancellable]()
}

// MARK: - IBActions

extension SingleImageImportViewController {
    @IBAction
    private func deleteImage(_ sender: NSButton) {
        // Straightforward, so far.
        imageWell.image = nil
    }

    @IBAction
    private func importImage(_ sender: NSButton) {
        print("Import iamge!")
    }
}

// MARK: - NSViewController Overrides

extension SingleImageImportViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Hide the button when there is no image.
        imageWell.publisher(for: \.image)
            .map { image in
                image != nil
            }
            .sink { [deleteButton, dropImageLabel] hasImage in
                deleteButton?.isHidden = !hasImage
                dropImageLabel?.isHidden = hasImage
            }
            .store(in: &subscriptions)
    }
}
