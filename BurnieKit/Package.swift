// swift-tools-version: 6.0
import PackageDescription

/// What every module folder holds besides its sources: the module's agent instructions.
let instructions = ["AGENTS.md", "CLAUDE.md"]

/// One module per layer (SPEC 3). Dependencies go one way, as SPEC 3.2 lists them.
let package = Package(
    name: "BurnieKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "BurnieDomain", targets: ["BurnieDomain"]),
        .library(name: "BurnieInterface", targets: ["BurnieInterface"]),
        .library(name: "BurnieProviders", targets: ["BurnieProviders"]),
        .library(name: "BurnieApplication", targets: ["BurnieApplication"]),
        .library(name: "BurnieComponents", targets: ["BurnieComponents"]),
        .library(name: "BurnieInfra", targets: ["BurnieInfra"]),
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
        // Test code: only test targets link it, so it's no product.
        .target(
            name: "BurnieTestSupport",
            dependencies: ["BurnieDomain", "BurnieInterface"],
            path: "Tests/BurnieTestSupport",
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
    ]
)
