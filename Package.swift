// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Raw",
    platforms: [
        .iOS(.v15), .macOS(.v11),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Raw",
            targets: ["Raw"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Raw",
            dependencies: [],
            resources: [
                .process("Keys/ImageIO.txt"),
                .process("Keys/Supported.txt"),
                .process("Keys/Unsupported.txt"),
            ]
        ),
        .testTarget(
            name: "RawTests",
            dependencies: ["Raw"],
            resources: [
                
                // Test JPG, converted from a FUJI X-T2 RAW file
                .process("files/DSCF5353.jpeg")
            ]),
    ]
)
