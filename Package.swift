// swift-tools-version: 6.0
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
    targets: [
        .target(
            name: "PDFPagePicker",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "PDFPagePickerTests",
            dependencies: ["PDFPagePicker"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
