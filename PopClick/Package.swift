// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PopClick",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "PopClick",
            dependencies: [],
            path: "Sources",
            resources: [
                .copy("../Resources")
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        )
    ]
)
