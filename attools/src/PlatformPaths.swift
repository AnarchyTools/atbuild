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

import atfoundation

public enum Architecture {
    case x86_64
    case i386
    case armv7
    case arm64
}

extension Architecture: CustomStringConvertible {
    public var description: String {
        switch(self) {
            case .x86_64:
            return "x86_64"

            case .i386:
            return "i386"

            case .armv7:
            return "armv7"

            case .arm64:
            return "arm64"
        }
    }
}

func ==(a: Platform, b: Platform) -> Bool {
    switch(a, b) {
        case (.OSX, .OSX): return true
        case (.Linux, .Linux): return true
        case (.iOS(let a), .iOS(let b)) where a == b: return true
        default: return false
    }
}

public enum Platform {
    case OSX
    case Linux
    case iOS(Architecture)

    public init(string: String) {
        switch(string) {
            case "osx", "mac":
                self = Platform.OSX
            case "linux":
                self = Platform.Linux
            case "ios-x86_64":
                self = Platform.iOS(Architecture.x86_64)
            case "ios-i386":
                self = Platform.iOS(Architecture.i386)
            case "ios-armv7":
                self = Platform.iOS(Architecture.armv7)
            case "ios-arm64":
                self = Platform.iOS(Architecture.arm64)

            default:
                fatalError("Unknown platform \(string)")
        }
    }

    ///The overlays that should be enabled when building for this platform
    public var overlays: [String] {
        switch(self) {
            case .OSX:
                return ["atbuild.platform.osx", "atbuild.platform.mac"]
            case .Linux:
                return ["atbuild.platform.linux"]
            case .iOS:
                return ["atbuild.platform.ios"]
        }
    }

    ///The typical path to a toolchain binary of the platform
    var defaultToolchainBinaryPath: String {
        switch(self) {
            case .OSX, .iOS:
            return "\(defaultToolchainPath)/usr/bin/"
            case .Linux:
            return "\(defaultToolchainPath)/usr/local/bin/"
        }
    }

    public var defaultToolchainPath: String {
        switch(self) {
            case .OSX, .iOS:
                return "/Library/Developer/Toolchains/swift-latest.xctoolchain"
            case .Linux:
                return "/"
        }
    }

    var sdkPath: String? {
        switch(self) {
            case .OSX:
                return "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk"
            case .Linux:
                return nil
            case .iOS(.x86_64), .iOS(.i386):
                return "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator9.3.sdk"
            case .iOS(.armv7), .iOS(.arm64):
                return "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS9.3.sdk"
        }
    }

    var architecture: Architecture {
        switch(self) {
            case .OSX, .Linux:
                return Architecture.x86_64
            case .iOS(let arch):
                return arch
        }
    }

    var dynamicLibraryExtension: String {
        switch(self) {
            case .OSX, .iOS:
                return ".dylib"
            case .Linux:
                return ".so"
        }
    }

    ///The platform on which atbuild is currently running
    public static var hostPlatform: Platform {
        #if os(OSX)
        return Platform.OSX
        #elseif os(Linux)
        return Platform.Linux
        #endif
    }

    ///The platform for which atbuild is currently building
    ///By default, we build for the hostPlatform
    public static var targetPlatform: Platform = Platform.hostPlatform

    ///The platform on which the build will take place (e.g. swift-build-tool will run).
    ///Ordinarily we build on the hostPlatform, but in the case of bootstrapping,
    ///we may be only emitting a yaml, which the actual build occuring
    /// on some other platform than either the host or the target.
    public static var buildPlatform: Platform = Platform.hostPlatform
}

extension Platform: CustomStringConvertible {
    public var description: String {
        switch(self) {
            case .OSX:
            return "osx"
            case .Linux:
            return "linux"
            case .iOS(let architecture):
            return "ios-\(architecture)"
        }
    }
}

func findToolPath(toolName: String, toolchain: String) -> Path {

    if Platform.buildPlatform == Platform.hostPlatform {
        //poke around on the filesystem
        //look in /usr/bin
        let usrBin = Path("\(toolchain)/usr/bin/\(toolName)")
        if FS.fileExists(path: usrBin) { return usrBin }
        //look in /usr/local/bin
        let usrLocalBin = Path("\(toolchain)/usr/local/bin/\(toolName)")
        if FS.fileExists(path: usrLocalBin) { return usrLocalBin }

        //swift-build-tool isn't available in 2.2.
        //If we're looking for SBT, try in the default location
        if toolName == "swift-build-tool" {
            let sbtPath = Path("\(Platform.hostPlatform.defaultToolchainPath)/usr/bin/\(toolName)")
            if FS.fileExists(path: sbtPath) { return sbtPath }

        }
    }
    else {
        //file system isn't live; hope the path is in a typical place
        return Path("\(Platform.buildPlatform.defaultToolchainBinaryPath)\(toolName)")
    }
    
    fatalError("Can't find a path for \(toolName)")
}