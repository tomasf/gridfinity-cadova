// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "gridfinity-cadova",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "Gridfinity", targets: ["Gridfinity"]),
        .executable(name: "generator", targets: ["generator"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tomasf/Cadova.git", from: "1.0.0"),
        .package(url: "https://github.com/tomasf/Helical.git", from: "1.0.4"),
    ],
    targets: [
        .target(
            name: "Gridfinity",
            dependencies: ["Cadova", "Helical"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .executableTarget(
            name: "generator",
            dependencies: ["Gridfinity"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
    ]
)
