// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "OpenSharkMacOS",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "r1", targets: ["r1"]),
        .executable(name: "OpenSharkApp", targets: ["OpenSharkApp"]),
        .library(name: "R1Kit", targets: ["R1Kit"]),
    ],
    targets: [
        .target(
            name: "R1Kit",
            linkerSettings: [.linkedFramework("IOKit")]
        ),
        .executableTarget(
            name: "r1",
            dependencies: ["R1Kit"]
        ),
        .executableTarget(
            name: "OpenSharkApp",
            dependencies: ["R1Kit"]
        ),
        .testTarget(
            name: "R1KitTests",
            dependencies: ["R1Kit"]
        ),
    ]
)
