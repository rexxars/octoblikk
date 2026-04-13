// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "octoblikk",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "octoblikk",
            path: "Sources",
            exclude: ["Resources"],
            resources: [.process("Assets")],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/Resources/Info.plist",
                ]),
            ]
        ),
    ]
)
