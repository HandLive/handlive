// swift-tools-version: 6.0
import PackageDescription

// Kiểm thử bằng swift-testing: với Xcode, module `Testing` có sẵn; máy chỉ có Command Line Tools
// thì đặt HL_SWIFT_TESTING_PACKAGE=1 để kéo gói swift-testing.
let useSwiftTestingPackage = Context.environment["HL_SWIFT_TESTING_PACKAGE"] == "1"

// Asset catalog (.xcassets) và macro #Preview chỉ có với Xcode (actool, PreviewsMacros).
// Chế độ chỉ có Command Line Tools đi cùng cờ HL_SWIFT_TESTING_PACKAGE=1: catalog bị loại khỏi
// resource (màu lấy từ mã Swift sinh cùng lúc, cùng giá trị) và các khối #Preview bỏ qua bằng cờ
// HL_COMMAND_LINE_TOOLS_ONLY. Không đoán theo xcode-select vì manifest chạy trong sandbox dưới Xcode.
let hasXcode = !useSwiftTestingPackage
let colorCatalog = "Resources/Colors.xcassets"

let package = Package(
    name: "HLDesignSystem",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "HLDesignSystem", targets: ["HLDesignSystem"]),
    ],
    dependencies: useSwiftTestingPackage
        ? [.package(url: "https://github.com/swiftlang/swift-testing.git", branch: "release/6.2")]
        : [],
    targets: [
        .target(
            name: "HLDesignSystem",
            exclude: hasXcode ? [] : [colorCatalog],
            resources: (hasXcode ? [.process(colorCatalog)] : []) + [.copy("Resources/Fonts")], // font + OFL.txt đi cùng nhau (điều kiện của OFL)
            swiftSettings: hasXcode ? [] : [.define("HL_COMMAND_LINE_TOOLS_ONLY")]
        ),
        .testTarget(
            name: "HLDesignSystemTests",
            dependencies: ["HLDesignSystem"]
                + (useSwiftTestingPackage ? [.product(name: "Testing", package: "swift-testing")] : [])
        ),
    ]
)
