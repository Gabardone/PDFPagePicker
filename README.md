# PDFPagePicker
[![Swift Package Manager compatible](https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat)](https://github.com/apple/swift-package-manager)

A macOS API to allow for UI presentation of a pdf page picker when importing pdf data into a single image.

The API includes two facilities:

- A `NSResponder` extension that allows for requesting a single page out of pdf data or a pdf file, as well as an
interception point for configuring presentation of that page picker.
- `ImageWell`, a subclass of `NSImageView` that intercepts paste and drop operations and presents the pdf page picker
if needed.

## Installation

Select "Add package…" in the Xcode File menu and paste the URL for this same repository in the search bar. Then `import
PDFPagePicker` in whichever files need it.

## Usage

The best way to see how it works is to check the Test application at
https://github.com/Gabardone/PDFPagePickerTestApp.git and examine how it uses the API in this package.

For any of the options, if the default presentation behavior doesn't work for your needs you can always override
`NSResponder.presentPDFPagePicker` any place down the responder chain where it will catch the call.

### Direct API

For example, assume that your app has already obtained a pdf file during an import operation, and you want to save the
image for the selected page, if the user selects any. You would make a call similar to the following from any component
of the responder chain (i.e. the view controller coordinating the process), give or take some localization:

```swift
pickPDFPage(from: pdfFileURL, verb: "Import") { image in
    save(image)
}
```

### `ImageWell`

Use it as a direct replacement for an editable
[`NSImageWell`](https://developer.apple.com/documentation/appkit/nsimageview). It will also ensure that pasting or
dropping image files on the well will extract the image data off the file instead of the file's icon.
