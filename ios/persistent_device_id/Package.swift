// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "persistent_device_id",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "persistent-device-id", targets: ["persistent_device_id"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "persistent_device_id",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
