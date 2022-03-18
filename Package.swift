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
                .copy("Files/TEST_8BIM.psd"),
                .copy("Files/TEST_APPLE_GPS.JPG"),
                .copy("Files/TEST_CANON.cr2"),
                .copy("Files/TEST_CIFF.CRW"),
                .copy("Files/TEST_DNG.dng"),
                .copy("Files/TEST_GIF.gif"),
                .copy("Files/TEST_IPTC_2.jpg"),
                .copy("Files/TEST_IPTC.jpg"),
                .copy("Files/TEST_NIKON.nef"),
                .copy("Files/TEST_PICTURESTYLE.CR2"),
                .copy("Files/TEST_PNG.png"),
                .copy("Files/TEST_unreadable.txt"),
            ]),
    ]
)
