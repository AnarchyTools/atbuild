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

func findToolPath(toolName: String, toolchain: String) -> String {
    //look in /usr/bin
    let manager = NSFileManager.defaultManager()
    let usrBin = "\(toolchain)/usr/bin/\(toolName)"
    if manager.fileExists(atPath: usrBin) { return usrBin }
    //look in /usr/local/bin
    let usrLocalBin = "\(toolchain)/usr/local/bin/\(toolName)"
    if manager.fileExists(atPath: usrLocalBin) { return usrLocalBin }

    //swift-build-tool isn't available in 2.2.
    //If we're looking for SBT, try in the default location
    if toolName == "swift-build-tool" {
        let sbtPath = "\(DefaultToolchainPath)/usr/bin/\(toolName)"
        if manager.fileExists(atPath: sbtPath) { return sbtPath }

    }

    
    fatalError("Can't find a path for \(toolName)")
}

#if os(OSX)
    let SDKPath = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk"
    public let DefaultToolchainPath = "/Library/Developer/Toolchains/swift-latest.xctoolchain"
    let DynamicLibraryExtension = ".dylib"
    let Architecture = "x86_64"
#elseif os(Linux)
    let SwiftCPath = "/usr/local/bin/swiftc"
    public let DefaultToolchainPath = "/"
    let DynamicLibraryExtension = ".so"
    let Architecture = "x86_64"
#endif