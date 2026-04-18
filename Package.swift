// swift-tools-version: 5.9
// Pure-Swift core of the Benji app — covers the calculator math,
// formatting, history filtering, and export schema. Used by the iOS
// app target (via the Xcode project) and by `swift test` so the
// business logic can be verified without an iOS Simulator.
import PackageDescription

let package = Package(
    name: "BenjiCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "BenjiCore", targets: ["BenjiCore"])
    ],
    dependencies: [
        // Apple's cross-platform CryptoKit shim. On Apple platforms the
        // built-in `CryptoKit` is preferred — see `PasswordHasher.swift`.
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "BenjiCore",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto", condition: .when(platforms: [.linux, .windows, .android]))
            ],
            path: "Benji/Core"
        ),
        .testTarget(
            name: "BenjiCoreTests",
            dependencies: ["BenjiCore"],
            path: "Tests/BenjiCoreTests"
        )
    ]
)
