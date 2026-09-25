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
    name: "HLCrypto",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "HLCrypto", targets: ["HLCrypto"])
    ],
    dependencies: [.package(path: "../HLProtocol")] + testingPackage,
    targets: [
        .target(name: "HLCrypto", dependencies: ["HLProtocol"]),
        .testTarget(name: "HLCryptoTests", dependencies: ["HLCrypto", "HLProtocol"] + testingProduct)
    ]
)
