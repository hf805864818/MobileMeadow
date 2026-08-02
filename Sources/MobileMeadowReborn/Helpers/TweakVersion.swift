/*
  TweakVersion.swift
  MobileMeadow Reborn

  Version constant — auto-updated by CI.
  Do not edit manually; the version is managed by scripts/auto_version.sh
*/

import Foundation

struct TweakVersion {
    /// 当前插件版本号（由 CI 自动更新）
    static let version: String = "1.0.13"

    /// 带前缀的版本号字符串，用于界面显示
    static var displayVersion: String {
        return "v\(version)"
    }
}
