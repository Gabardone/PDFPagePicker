# PDFPagePicker
[![Swift Package Manager compatible](https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat)](https://github.com/apple/swift-package-manager)

A macOS API to allow for UI presentation of a pdf page picker when importing pdf data into a single image.

The API includes two facilities:

- A `NSResponder` extension that allows for requesting a single page out of pdf data or a pdf file, as well as an
interception point for configuring presentation of that page picker.
- `ImageWell`, a subclass of `NSImageView` that intercepts paste and drop operations and presents the pdf page picker
if needed.

## Usage

The repository contains a sample test app `PDFPagePickerTestApp` which illustrates basic use of the package API.

For any of the options, If the default presentation behavior doesn't work for your needs, you can always override
`NSResponder.presentPDFPagePicker` wherever it makes the most sense.

### Direct API

Say for exmaple that your app has already obtained a pdf file during an import operation, and you want to save the image
for the selected page (if any). The call to be made, from any component of the responder chain (i.e. the view controller
coordinating the process) would look as follows, give or take some localization:

```swift
pickPDFPage(from: pdfFileURL, verb: "Import") { image in
    save(image)
}
```

### `ImageWell`

Use it as a direct replacement of `NSImageWell`. It will also behave a bit better than the framework superclass when
dealing with image files.
