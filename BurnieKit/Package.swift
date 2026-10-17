// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BurnieKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "BurnieCore", targets: ["BurnieCore"]),
        .library(name: "BurnieSystem", targets: ["BurnieSystem"]),
    ],
    targets: [
        .target(name: "BurnieCore", exclude: ["AGENTS.md", "CLAUDE.md"]),
        .target(name: "BurnieSystem", dependencies: ["BurnieCore"], exclude: ["AGENTS.md", "CLAUDE.md"]),
        // Test code: only test targets link it, so it's no product.
        .target(
            name: "BurnieTestSupport",
            dependencies: ["BurnieCore"],
            path: "Tests/BurnieTestSupport",
            exclude: ["AGENTS.md", "CLAUDE.md"]
        ),
        .testTarget(name: "BurnieCoreTests", dependencies: ["BurnieCore", "BurnieTestSupport"], resources: [.copy("Fixtures")]),
        .testTarget(name: "BurnieSystemTests", dependencies: ["BurnieSystem"]),
    ]
)
