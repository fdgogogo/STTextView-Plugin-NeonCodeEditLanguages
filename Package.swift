// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NeonCodeEditLanguagesPlugin",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "NeonCodeEditLanguagesPlugin",
            targets: ["NeonCodeEditLanguagesPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/STTextView", from: "0.8.13"),
        .package(url: "https://github.com/ChimeHQ/Neon.git", from: "0.6.0"),
        .package(url: "https://github.com/CodeEditApp/CodeEditLanguages", exact: "0.1.17")
    ],
    targets: [
        .target(
            name: "NeonCodeEditLanguagesPlugin",
            dependencies: [
                .product(name: "STTextView", package: "STTextView"),
                "Neon",
                .product(name: "CodeEditLanguages", package: "CodeEditLanguages")
            ]
        )
    ]
)
