// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PDFPagePicker",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "PDFPagePicker",
            targets: ["PDFPagePicker"]
        ),
    ],
    targets: [
        .target(
            name: "PDFPagePicker",
            dependencies: []
        ),
        .testTarget(
            name: "PDFPagePickerTests",
            dependencies: ["PDFPagePicker"]
        )
    ]
)
