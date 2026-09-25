// swift-tools-version: 6.0
import PackageDescription

// Máy chỉ có Command Line Tools không có Testing đi kèm Xcode: đặt HL_SWIFT_TESTING_PACKAGE=1
// để kéo gói swift-testing. Dưới Xcode (CI) không đặt biến, dùng Testing có sẵn.
let useSwiftTestingPackage = Context.environment["HL_SWIFT_TESTING_PACKAGE"] == "1"
let testingPackage: [Package.Dependency] = useSwiftTestingPackage
    ? [.package(url: "https://github.com/swiftlang/swift-testing.git", branch: "release/6.2")]
    : []
let testingProduct: [Target.Dependency] = useSwiftTestingPackage
    ? [.product(name: "Testing", package: "swift-testing")]
    : []

let package = Package(
    name: "HLTransport",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "HLTransport", targets: ["HLTransport"])
    ],
    dependencies: [.package(path: "../HLProtocol"), .package(path: "../HLCrypto")] + testingPackage,
    targets: [
        .target(name: "HLTransport", dependencies: ["HLProtocol", "HLCrypto"]),
        .testTarget(name: "HLTransportTests", dependencies: ["HLTransport", "HLProtocol", "HLCrypto"] + testingProduct)
    ]
)
