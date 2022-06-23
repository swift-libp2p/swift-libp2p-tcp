// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-libp2p-tcp",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "LibP2PTCP",
            targets: ["LibP2PTCP"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.

        // LibP2P Core Modules
        .package(url: "https://github.com/swift-libp2p/swift-libp2p.git", .upToNextMajor(from: "0.1.0")),
        
        // NIO Extras
        .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "LibP2PTCP",
            dependencies: [
                .product(name: "LibP2P", package: "swift-libp2p"),
                .product(name: "NIOExtras", package: "swift-nio-extras"),
            ]),
        .testTarget(
            name: "LibP2PTCPTests",
            dependencies: ["LibP2PTCP"]),
    ]
)
