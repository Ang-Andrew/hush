// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Hush",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        .executable(name: "Hush", targets: ["Hush"])
    ],
    dependencies: [
        .package(path: "Vendor/whisper.spm")
    ],
    targets: [
        .executableTarget(
            name: "Hush",
            dependencies: [
                .product(name: "whisper", package: "whisper.spm")
            ],
            path: "Sources/Hush",
            resources: [
                // We expect the model to be possibly a resource or loaded from a fixed path.
                // For now, we will handle model loading dynamically or expect it in Resources.
                // .process("Resources") 
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)
