// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Buble",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(name: "Buble", targets: ["Buble"]),
        .executable(name: "BubleLiveSmoke", targets: ["BubleLiveSmoke"])
    ],
    targets: [
        .target(
            name: "Buble",
            path: "Sources/Buble"
        ),
        .executableTarget(
            name: "BubleLiveSmoke",
            dependencies: ["Buble"],
            path: "Examples/LiveSmoke"
        ),
        .executableTarget(
            name: "TextToImage",
            dependencies: ["Buble"],
            path: "Examples/TextToImage"
        ),
        .executableTarget(
            name: "ImageToImage",
            dependencies: ["Buble"],
            path: "Examples/ImageToImage"
        ),
        .executableTarget(
            name: "TextToVideo",
            dependencies: ["Buble"],
            path: "Examples/TextToVideo"
        ),
        .executableTarget(
            name: "AppGeneration",
            dependencies: ["Buble"],
            path: "Examples/AppGeneration"
        ),
        .executableTarget(
            name: "OpenAIChat",
            dependencies: ["Buble"],
            path: "Examples/OpenAIChat"
        ),
        .executableTarget(
            name: "AnthropicMessages",
            dependencies: ["Buble"],
            path: "Examples/AnthropicMessages"
        ),
        .executableTarget(
            name: "GeminiGenerate",
            dependencies: ["Buble"],
            path: "Examples/GeminiGenerate"
        ),
        .testTarget(
            name: "BubleTests",
            dependencies: ["Buble"],
            path: "Tests/BubleTests"
        )
    ]
)
