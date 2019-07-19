// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "chatbot",
    products: [
        .library(name: "chatbot", targets: ["Run"])
    ],
    dependencies: [
        // SQLite query builder
        .package(url: "https://github.com/kinironote/SQLite.swift.git", .branch("master")),

        // Python connecter
        .package(url: "https://github.com/pvieito/PythonKit.git", .branch("master")),

        // Regex helper
        .package(url: "https://github.com/sharplet/Regex.git", from: "2.1.0"),

        // Logging
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),

        // HTTP Server
        .package(url: "https://github.com/httpswift/swifter.git", from: "1.4.5"),

        // HTTP Client
        // .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0-beta.6")
        .package(url: "https://github.com/micahbenn/Just.git", .branch("master"))
    ],
    targets: [
        .target(name: "Bot", dependencies: ["SQLite", "PythonKit", "Regex", "Logging"]),
        .target(name: "Interfaces", dependencies: ["Bot", "Swifter", "Just", "Logging"]),
        .testTarget(name: "AppTests", dependencies: ["Interfaces", "Bot"])
    ]
)
