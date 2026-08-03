// swift-tools-version:5.2

import PackageDescription
import Foundation

let projectDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()

@dynamicMemberLookup struct TheosConfiguration {
    private let dict: [String: String]
    init(at path: String) {
        let configURL = URL(fileURLWithPath: path, relativeTo: projectDir)
        guard let infoString = try? String(contentsOf: configURL) else {
            fatalError("""
            Could not find Theos SPM config. Have you run `make spm` yet?
            """)
        }
        let pairs = infoString.split(separator: "\n").map {
            $0.split(
                separator: "=", maxSplits: 1,
                omittingEmptySubsequences: false
            ).map(String.init)
        }.map { ($0[0], $0[1]) }
        dict = Dictionary(uniqueKeysWithValues: pairs)
    }
    subscript(
        key: String,
        or defaultValue: @autoclosure () -> String? = nil
    ) -> String {
        if let value = dict[key] {
            return value
        } else if let def = defaultValue() {
            return def
        } else {
            fatalError("""
            Could not get value of key '\(key)' from Theos SPM config. \
            Try running `make spm` again.
            """)
        }
    }
    subscript(dynamicMember key: String) -> String { self[key] }
}
let conf = TheosConfiguration(at: ".theos/spm_config")

let theosPath = conf.theos
let sdk = conf.sdk
let resourceDir = conf.swiftResourceDir
let deploymentTarget = conf.deploymentTarget
// 关键修复：优先使用 THEOS_CURRENT_ARCH 环境变量，而不是 spm_config 中的 arch
// 因为 make spm 生成 spm_config 时会用 ARCHS 的第一个值（arm64），
// 导致 arm64e 构建时 SPM 仍然编译 arm64
let arch = ProcessInfo.processInfo.environment["THEOS_CURRENT_ARCH"] ?? conf[key: "arch", or: "arm64"]
let triple = "\(arch)-apple-ios\(deploymentTarget)"

let libFlags: [String] = [
    "-F\(theosPath)/vendor/lib", "-F\(theosPath)/lib",
    "-I\(theosPath)/vendor/include", "-I\(theosPath)/include"
]

let cFlags: [String] = libFlags + [
    "-target", triple, "-isysroot", sdk,
    "-Wno-unused-command-line-argument", "-Qunused-arguments",
]

let cxxFlags: [String] = [
]

let swiftFlags: [String] = libFlags + [
    "-target", triple, "-sdk", sdk, "-resource-dir", resourceDir,
]

let package = Package(
    name: "MobileMeadowReborn",
    platforms: [.iOS(deploymentTarget)],
    products: [
        .library(
            name: "MobileMeadowReborn",
            targets: ["MobileMeadowReborn"]
        ),
    ],
    targets: [
        .target(
            name: "MobileMeadowRebornC",
            cSettings: [.unsafeFlags(cFlags)],
            cxxSettings: [.unsafeFlags(cxxFlags)]
        ),
        .target(
            name: "MobileMeadowReborn",
            dependencies: ["MobileMeadowRebornC"],
            swiftSettings: [.unsafeFlags(swiftFlags)]
        ),
    ]
)
