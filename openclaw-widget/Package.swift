// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "OpenClawWidget",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "OpenClawWidget",
            targets: ["OpenClawWidget"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "OpenClawWidget",
            dependencies: [],
            path: "OpenClawWidget"
        ),
    ]
)
