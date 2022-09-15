// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "SwiftProfileImagePicker",
    products: [
        .library(
            name: "SwiftProfileImagePicker",
            targets: ["SwiftProfileImagePicker"]),
    ],
    dependencies: [
        .package(name: "MMSCameraViewController",
            url: "https://github.com/BlackBookHotels/MMSCameraViewController.git",
                .branch("master")
        )

    ],
    targets: [
        .target(
            name: "SwiftProfileImagePicker",
            dependencies: ["MMSCameraViewController"])
        ,
        .testTarget(
            name: "SwiftProfileImagePickerTests",
            dependencies: ["SwiftProfileImagePicker"]),
    ]
)
