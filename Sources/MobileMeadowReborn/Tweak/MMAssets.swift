/*
 
 MIT License

 Copyright (c) 2024 ★ Install Package Files

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
*/

import Foundation
import UIKit

class MMAssets: NSObject {
    
    static var assetsPath: String {
        var path: String = "/var/jb/Library/Application Support/MobileMeadow/Assets"
        if !FileManager.default.fileExists(atPath: path) {
            path = "/Library/Application Support/MobileMeadow/Assets"
        }
        
        return path
    }

    /// 串行队列用于保护 cachedImages 和 imageCountsForPrefixes 的线程安全访问
    private static let syncQueue = DispatchQueue(label: "com.pkgfiles.mobilemeadow.assets.sync")
    private static var cachedImages: [String: UIImage] = [:]
    private static var imageCountsForPrefixes: [String: NSNumber] = [:]
    
    // Overriding init methods to prevent instantiation
    private override init() {
        fatalError("Don't use -init for this class.")
    }
    
    static func imageNamed(_ name: String) -> UIImage? {
        // 线程安全：在串行队列中读取缓存
        var cachedImage: UIImage?
        syncQueue.sync {
            cachedImage = cachedImages[name]
        }
        if let cachedImage = cachedImage {
            return cachedImage
        }

        let imagePath = "\(assetsPath)/\(name).png"
        if let image = UIImage(contentsOfFile: imagePath) {
            syncQueue.sync {
                cachedImages[name] = image
            }
            return image
        }
        return nil
    }
    
    static func randomImage(withPrefix prefix: String) -> UIImage? {
        var imageCount: NSNumber?
        syncQueue.sync {
            imageCount = imageCountsForPrefixes[prefix]
        }

        if let imageCount = imageCount {
            return getRandomImage(for: prefix, count: imageCount.uintValue)
        } else {
            let imageCountRaw = findImageCount(for: prefix)
            syncQueue.sync {
                imageCountsForPrefixes[prefix] = NSNumber(value: imageCountRaw)
            }
            return getRandomImage(for: prefix, count: imageCountRaw)
        }
    }
    
    private static func findImageCount(for prefix: String) -> UInt {
        var imageCountRaw: UInt = 0
        var isDir: ObjCBool = false
        var path: String
        repeat {
            path = "\(assetsPath)/\(prefix)_\(imageCountRaw).png"
            imageCountRaw += 1
        } while FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && !isDir.boolValue
        return imageCountRaw - 1
    }
    
    private static func getRandomImage(for prefix: String, count: UInt) -> UIImage? {
        guard count > 0 else { return nil }
        let randomIndex = UInt32.random(in: 0..<UInt32(count))
        return imageNamed("\(prefix)_\(randomIndex)")
    }
}
