// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "Faraway", platforms: [.macOS(.v14)],
    products: [.executable(name: "Faraway", targets: ["Faraway"])],
    targets: [
        .target(name: "RestCore"),
        .executableTarget(name: "Faraway", dependencies: ["RestCore"]),
        .testTarget(name: "RestCoreTests", dependencies: ["RestCore"])
    ]
)
