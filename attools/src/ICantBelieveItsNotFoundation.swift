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
enum CopyError: ErrorType {
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
        let permission = (try! attributesOfItemAtPath(srcPath)[NSFilePosixPermissions] as! NSNumber).unsignedShortValue
        let fd_to = open(dstPath, O_WRONLY | O_CREAT | O_EXCL, permission)
        if fd_to < 0 {
            throw CopyError.CantOpenDestFile(errno)
        }
        defer { precondition(close(fd_to) >= 0) }
        
        var buf = [UInt8](count: 4096, repeatedValue: 0)
        
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
                writeSlice = writeSlice[writeSlice.startIndex.advancedBy(nwritten)..<writeSlice.endIndex]
                if writeSlice.count == 0 { break }
            }
        }
    }
}