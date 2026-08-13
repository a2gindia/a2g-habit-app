// swift-tools-version: 6.0
import PackageDescription

// EconomyKit holds the app's pure domain logic — rates, denominators, scoring,
// framing, formatting. It has NO dependency on SwiftUI or SwiftData, so it
// compiles and unit-tests on plain macOS via `swift test`, with no Xcode.
// The iOS app's SwiftData @Model types import this package.
let package = Package(
    name: "EconomyKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "EconomyKit", targets: ["EconomyKit"]),
    ],
    targets: [
        .target(name: "EconomyKit"),
        .testTarget(name: "EconomyKitTests", dependencies: ["EconomyKit"]),
        // Dev-only harness. The real suite is EconomyKitTests (XCTest), which
        // runs under Xcode/CI. This target mirrors the load-bearing assertions
        // so the math can be verified with the bare `swift` CLI on a machine
        // with no Xcode installed: `swift run verify`. Not shipped in the app.
        .executableTarget(name: "verify", dependencies: ["EconomyKit"]),
    ]
)
