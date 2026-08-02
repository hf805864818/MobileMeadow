#!/bin/bash
# ==============================================================================
# auto_version.sh — MobileMeadow Reborn 版本自动递增脚本
# ==============================================================================
# 功能：
#   1. 读取 control 文件中的当前版本号
#   2. 自动递增 patch 版本号（如 1.0.2 → 1.0.3）
#   3. 更新 control 文件
#   4. 更新 Sources/MobileMeadowReborn/Helpers/TweakVersion.swift
#   5. 更新 Preferences/Sources/MobileMeadowRebornPrefs/Helpers/TweakVersion.swift
#   6. 更新 Preferences/Resources/Root.plist 中的版本显示
#
# 用法：在项目根目录执行 bash scripts/auto_version.sh
# 输出：NEW_VERSION=1.0.3（供 GitHub Actions 使用）
# ==============================================================================

set -euo pipefail

# 项目根目录（脚本所在目录的上级）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

CONTROL_FILE="control"
TWEAK_VERSION_FILE="Sources/MobileMeadowReborn/Helpers/TweakVersion.swift"
PREFS_VERSION_FILE="Preferences/Sources/MobileMeadowRebornPrefs/Helpers/TweakVersion.swift"
ROOT_PLIST="Preferences/Resources/Root.plist"

# ---- 读取当前版本号 ----
if [ ! -f "$CONTROL_FILE" ]; then
    echo "ERROR: control file not found at $CONTROL_FILE"
    exit 1
fi

CURRENT_VERSION=$(grep "^Version:" "$CONTROL_FILE" | awk '{print $2}')
if [ -z "$CURRENT_VERSION" ]; then
    echo "ERROR: Could not read version from control file"
    exit 1
fi

echo "Current version: $CURRENT_VERSION"

# ---- 解析并递增版本号 ----
IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]}"
MINOR="${VERSION_PARTS[1]}"
PATCH="${VERSION_PARTS[2]}"

NEW_PATCH=$((PATCH + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"

echo "New version: $NEW_VERSION"

# ---- 更新 control 文件 ----
if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/^Version: .*/Version: ${NEW_VERSION}/" "$CONTROL_FILE"
else
    sed -i "s/^Version: .*/Version: ${NEW_VERSION}/" "$CONTROL_FILE"
fi
echo "✓ Updated control file: Version: ${NEW_VERSION}"

# ---- 更新 TweakVersion.swift (主 Tweak) ----
if [ -f "$TWEAK_VERSION_FILE" ]; then
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s/static let version: String = \".*\"/static let version: String = \"${NEW_VERSION}\"/" "$TWEAK_VERSION_FILE"
    else
        sed -i "s/static let version: String = \".*\"/static let version: String = \"${NEW_VERSION}\"/" "$TWEAK_VERSION_FILE"
    fi
    echo "✓ Updated $TWEAK_VERSION_FILE"
fi

# ---- 更新 TweakVersion.swift (Preferences) ----
if [ -f "$PREFS_VERSION_FILE" ]; then
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s/static let version: String = \".*\"/static let version: String = \"${NEW_VERSION}\"/" "$PREFS_VERSION_FILE"
    else
        sed -i "s/static let version: String = \".*\"/static let version: String = \"${NEW_VERSION}\"/" "$PREFS_VERSION_FILE"
    fi
    echo "✓ Updated $PREFS_VERSION_FILE"
fi

# ---- 更新 Root.plist 中的页脚版本号 ----
if [ -f "$ROOT_PLIST" ]; then
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s/© 2024, ★ Install Package Files · v[0-9.]*/© 2024, ★ Install Package Files · v${NEW_VERSION}/" "$ROOT_PLIST"
    else
        sed -i "s/© 2024, ★ Install Package Files · v[0-9.]*/© 2024, ★ Install Package Files · v${NEW_VERSION}/" "$ROOT_PLIST"
    fi
    echo "✓ Updated $ROOT_PLIST footer text"
fi

# ---- 输出新版本号（供 CI 使用） ----
echo ""
echo "NEW_VERSION=${NEW_VERSION}"
