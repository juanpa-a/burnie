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
        .target(name: "BurnieCore", exclude: ["AGENTS.md"]),
        .target(name: "BurnieSystem", dependencies: ["BurnieCore"], exclude: ["AGENTS.md"]),
        .testTarget(name: "BurnieCoreTests", dependencies: ["BurnieCore"], resources: [.copy("Fixtures")]),
        .testTarget(name: "BurnieSystemTests", dependencies: ["BurnieSystem"]),
    ]
)
