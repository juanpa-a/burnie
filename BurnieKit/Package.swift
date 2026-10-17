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
        .library(name: "BurnieProviders", targets: ["BurnieProviders"]),
        .library(name: "BurnieInfra", targets: ["BurnieInfra"]),
        .library(name: "BurnieApplication", targets: ["BurnieApplication"]),
        .library(name: "BurnieComponents", targets: ["BurnieComponents"]),
        .library(name: "BurnieCore", targets: ["BurnieCore"]),
        .library(name: "BurnieSystem", targets: ["BurnieSystem"]),
        // For the app's Xcode test target (BurnieAppTests), which links packages only through products.
        .library(name: "LegacyTestSupport", targets: ["LegacyTestSupport"]),
    ],
    dependencies: [
        // Pinned: Sparkle replaces the installed app, so a new version comes in through a reviewed PR.
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0"),
    ],
    targets: [
        .target(name: "BurnieDomain", exclude: instructions),
        .target(name: "BurnieInterface", dependencies: ["BurnieDomain"], exclude: instructions),
        .target(name: "BurnieProviders", dependencies: ["BurnieDomain", "BurnieInterface"], exclude: instructions),
        .target(name: "BurnieApplication", dependencies: ["BurnieDomain", "BurnieInterface"], exclude: instructions),
        .target(
            name: "BurnieComponents",
            dependencies: ["BurnieDomain", "BurnieInterface"],
            exclude: instructions,
            resources: [.process("Resources")]
        ),
        .target(
            name: "BurnieInfra",
            dependencies: ["BurnieDomain", "BurnieInterface", .product(name: "Sparkle", package: "Sparkle")],
            exclude: instructions
        ),
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
        .testTarget(name: "BurnieApplicationTests", dependencies: ["BurnieApplication", "BurnieTestSupport"]),
        .testTarget(name: "BurnieComponentsTests", dependencies: ["BurnieComponents", "BurnieTestSupport"]),
        .testTarget(name: "BurnieInfraTests", dependencies: ["BurnieInfra", "BurnieTestSupport"]),
        .testTarget(name: "EquivalenceTests", dependencies: ["BurnieCore", "LegacyTestSupport", "BurnieDomain"]),
        .testTarget(name: "BurnieCoreTests", dependencies: ["BurnieCore", "LegacyTestSupport"], resources: [.copy("Fixtures")]),
        .testTarget(name: "BurnieSystemTests", dependencies: ["BurnieSystem"]),
    ]
)
