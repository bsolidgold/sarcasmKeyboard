// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SarcasmKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SarcasmKit",
            targets: ["SarcasmKit"]
        )
    ],
    targets: [
        .target(
            name: "SarcasmKit",
            path: "Sources/SarcasmKit"
        ),
        .testTarget(
            name: "SarcasmKitTests",
            dependencies: ["SarcasmKit"],
            path: "Tests/SarcasmKitTests"
        )
    ]
)
