// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "InputPilot",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "InputPilot", targets: ["InputPilot"])
    ],
    targets: [
        .executableTarget(
            name: "InputPilot",
            path: "Sources/InputPilot",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        )
    ]
)
