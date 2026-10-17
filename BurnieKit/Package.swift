// swift-tools-version: 6.0
import PackageDescription

/// What every module folder holds besides its sources: the module's agent instructions.
let instructions = ["AGENTS.md", "CLAUDE.md"]

let package = Package(
    name: "BurnieKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "BurnieDomain", targets: ["BurnieDomain"]),
        .library(name: "BurnieInterface", targets: ["BurnieInterface"]),
        .library(name: "BurnieCore", targets: ["BurnieCore"]),
        .library(name: "BurnieSystem", targets: ["BurnieSystem"]),
        // For the app's Xcode test target (BurnieAppTests), which links packages only through products.
        .library(name: "LegacyTestSupport", targets: ["LegacyTestSupport"]),
    ],
    targets: [
        .target(name: "BurnieDomain", exclude: instructions),
        .target(name: "BurnieInterface", dependencies: ["BurnieDomain"], exclude: instructions),
        .target(name: "BurnieProviders", dependencies: ["BurnieDomain", "BurnieInterface"], exclude: instructions),
        .target(name: "BurnieCore", exclude: instructions),
        .target(name: "BurnieSystem", dependencies: ["BurnieCore"], exclude: instructions),
        // Test code: only test targets link it.
        .target(
            name: "BurnieTestSupport",
            dependencies: ["BurnieDomain", "BurnieInterface"],
            path: "Tests/BurnieTestSupport",
            exclude: instructions
        ),
        .target(
            name: "LegacyTestSupport",
            dependencies: ["BurnieCore"],
            path: "Tests/LegacyTestSupport",
            exclude: instructions
        ),
        .testTarget(
            name: "BurnieDomainTests",
            dependencies: ["BurnieDomain", "BurnieTestSupport"],
            resources: [.copy("Fixtures")]
        ),
        .testTarget(name: "BurnieInterfaceTests", dependencies: ["BurnieInterface", "BurnieTestSupport"]),
        .testTarget(
            name: "BurnieProvidersTests",
            dependencies: ["BurnieProviders", "BurnieTestSupport"],
            resources: [.copy("Fixtures")]
        ),
        .testTarget(name: "BurnieCoreTests", dependencies: ["BurnieCore", "LegacyTestSupport"], resources: [.copy("Fixtures")]),
        .testTarget(name: "BurnieSystemTests", dependencies: ["BurnieSystem"]),
    ]
)
