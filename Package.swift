// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "SwiftProfileImagePicker",
    defaultLocalization: "en",
    products: [
        .library(
            name: "SwiftProfileImagePicker",
            targets: ["SwiftProfileImagePicker"]),
    ],
    dependencies: [
        .package(url: "https://github.com/BlackBookHotels/MMSCameraViewController.git",
                 branch: "master"
        )
    ],
    targets: [
        .target(
            name: "SwiftProfileImagePicker",
            dependencies: ["MMSCameraViewController"],
            resources: [
                .process("Assets")
            ])
        ,
        .testTarget(
            name: "SwiftProfileImagePickerTests",
            dependencies: ["SwiftProfileImagePicker"]),
    ]
)
