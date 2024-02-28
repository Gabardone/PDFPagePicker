// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PDFPagePicker",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "PDFPagePicker",
            targets: ["PDFPagePicker"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Gabardone/Iutilitis", .upToNextMinor(from: "0.0.1"))
    ],
    targets: [
        .target(
            name: "PDFPagePicker",
            dependencies: [
                "Iutilitis"
            ]
        ),
        .testTarget(
            name: "PDFPagePickerTests",
            dependencies: ["PDFPagePicker"]
        )
    ]
)
