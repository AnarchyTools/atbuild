// Copyright (c) 2016 Anarchy Tools Contributors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

//SR-138
extension String {
    var toNSString: NSString {
        #if os(Linux)
        return self.bridge()
        #elseif os(OSX)
        return (self as NSString)
        #endif
    }
}
extension NSString {
    var toString: String {
        #if os(Linux)
        return self.bridge()
        #elseif os(OSX)
        return (self as String)
        #endif
    }
}



// MARK: NSFileManager.copyItemAtPath
// https://github.com/apple/swift-corelibs-foundation/pull/248
enum CopyError: ErrorProtocol {
    case CantOpenSourceFile(Int32)
    case CantOpenDestFile(Int32)
    case CantReadSourceFile(Int32)
    case CantWriteDestFile(Int32)

}

extension NSFileManager {
    func copyItemAtPath_SWIFTBUG(srcPath: String, toPath dstPath: String) throws {
        let fd_from = open(srcPath, O_RDONLY)
        if fd_from < 0 {
            throw CopyError.CantOpenSourceFile(errno)
        }
        defer { precondition(close(fd_from) >= 0) }
        let permission_ = (try! attributesOfItem(atPath: srcPath)[NSFilePosixPermissions] as! NSNumber)

        #if os(OSX) || os(iOS)
        let permission = permission_.uint16Value
        #elseif os(Linux)
        let permission = permission_.unsignedIntValue
        #endif
        let fd_to = open(dstPath, O_WRONLY | O_CREAT | O_EXCL, permission)
        if fd_to < 0 {
            throw CopyError.CantOpenDestFile(errno)
        }
        defer { precondition(close(fd_to) >= 0) }

        var buf = [UInt8](repeating: 0, count: 4096)

        while true {
            let nread = read(fd_from, &buf, buf.count)
            if nread < 0 { throw CopyError.CantReadSourceFile(errno) }
            if nread == 0 { break }
            var writeSlice = buf[0..<nread]

            while true {
                var nwritten: Int! = nil
                writeSlice.withUnsafeBufferPointer({ (ptr) -> () in
                    nwritten = write(fd_to, ptr.baseAddress, ptr.count)
                })
                if nwritten < 0 {
                    throw CopyError.CantWriteDestFile(errno)
                }
                writeSlice = writeSlice[writeSlice.startIndex.advanced(by: nwritten)..<writeSlice.endIndex]
                if writeSlice.count == 0 { break }
            }
        }
    }
}

//These parts of Swift 3 Renaming are not yet implemented on Linux

#if os(Linux)

extension NSFileManager {
    func enumerator(atPath path: String) -> NSDirectoryEnumerator? {
        return self.enumeratorAtPath(path)
    }
    func createSymbolicLink(atPath path: String, withDestinationPath destPath: String) throws {
        return try self.createSymbolicLinkAtPath(path, withDestinationPath: destPath)
    }
    func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool,  attributes: [String : AnyObject]? = [:]) throws {
        return try self.createDirectoryAtPath(path, withIntermediateDirectories: createIntermediates, attributes: attributes)
    }
    func attributesOfItem(atPath path: String) throws -> [String : Any] {
        return try self.attributesOfItemAtPath(path)
    }
    func removeItem(atPath path: String) throws {
        return try self.removeItemAtPath(path)
    }
    func fileExists(atPath path: String) -> Bool {
        return self.fileExistsAtPath(path)
    }
}

extension String {
    func componentsSeparated(by separator: String) -> [String] {
        return self.componentsSeparatedByString(separator)
    }
    func write(toFile path: String, atomically useAuxiliaryFile:Bool, encoding enc: NSStringEncoding) throws {
        return try self.writeToFile(path, atomically: useAuxiliaryFile, encoding: enc)
    }
    func replacingOccurrences(of str: String, with: String) -> String {
        return self.stringByReplacingOccurrencesOfString(str, withString: with)
    }
}
#endif

//These parts are possibly? not yet implemented on OSX
#if os(OSX)
extension String {
    func componentsSeparated(by string: String) -> [String] {
        return self.components(separatedBy: string)
    }
}
#endif