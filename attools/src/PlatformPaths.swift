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

/**Drew's incredibly dumb string library */

extension String {
    func match(_ b: String) -> ClosedRange<String.CharacterView.Index>? {
        var idx = characters.startIndex
        while idx != endIndex {
            var l_idx_pre = idx
            var l_idx = idx
            var found = true
            for charB in b.characters {
                let charAL = characters[l_idx]
                if charAL != charB { found = false; break }
                l_idx_pre = l_idx
                l_idx = characters.index(after: l_idx)
            }
            if found {
                return ClosedRange(uncheckedBounds: (lower: idx, upper: l_idx_pre))
            }
            idx = characters.index(after: idx)
        }
        return nil
    }
    func prefix(to: String.CharacterView.Index) -> String {
        let notEndIndex = characters.index(before: characters.endIndex)
        let notStartIndex = characters.index(after: to)
        let closedRange = ClosedRange(uncheckedBounds: (lower: notStartIndex, upper: notEndIndex))
        var s = self
        s.removeSubrange(closedRange)
        return s
    }
}


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
    //specific platforms
    case OSX
    case Linux
    case iOS(Architecture)

    public static var toolchain: String? = nil

    private static var isXcode7: Bool {
        #if os(OSX)
        return FS.fileExists(path: Path("\(Platform.developerPath)/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk"))
        #else
        return false //no linux platform uses xcode 7
                     //unless you count Project Marklar 2
        #endif
    }

    private static var developerPath: String { 
        //first, look at the toolchain for clues
        if let match = Platform.toolchain!.match(".app/Contents/Developer") {
            return Platform.toolchain!.prefix(to: match.upperBound)
        }
        //assuming that failed, try xcode-select
        #if os(OSX)
        var xcode_select_path = ""
        anarchySystem("xcode-select -p", redirectOutput: &xcode_select_path)
        //lop off the newline
        var notEndIndex = xcode_select_path.characters.index(before: xcode_select_path.characters.endIndex)
        notEndIndex = xcode_select_path.characters.index(before: notEndIndex)
        xcode_select_path = xcode_select_path.prefix(to: notEndIndex)
        return xcode_select_path
        #else
        //on linux, let's just use /Applications/Xcode.app
        return "/Applications/Xcode.app/Contents/Developer"
        #endif
    }

    //generic platforms
    case iOSGeneric

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
            case "ios":
                self = Platform.iOSGeneric

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
            case .iOS, .iOSGeneric:
                return ["atbuild.platform.ios"]
        }
    }

    ///The typical path to a toolchain binary of the platform
    var defaultToolchainBinaryPath: String {
        switch(self) {
            case .OSX, .iOS, .iOSGeneric:
            return "\(defaultToolchainPath)/usr/bin/"
            case .Linux:
            return "\(defaultToolchainPath)/usr/local/bin/"
        }
    }

    public var defaultToolchainPath: String {
        switch(self) {
            case .OSX, .iOS, .iOSGeneric:
                return "/Library/Developer/Toolchains/swift-latest.xctoolchain"
            case .Linux:
                return "/"
        }
    }

    var sdkPath: String? {
        switch(self) {
            case .OSX:
                //look for a current-generation path
                if Platform.isXcode7 {
                    return "\(Platform.developerPath)/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk"
                }
                return "\(Platform.developerPath)/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
            case .Linux:
                return nil
            case .iOS(.x86_64), .iOS(.i386):
                if Platform.isXcode7 {
                    return "\(Platform.developerPath)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator9.3.sdk"
                }
                else {
                    return "\(Platform.developerPath)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk"
                }
            case .iOS(.armv7), .iOS(.arm64):
                if Platform.isXcode7 {
                    return "\(Platform.developerPath)/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS9.3.sdk"
                }
                else {
                    return "\(Platform.developerPath)/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
                }
            case .iOSGeneric:
                fatalError("No SDK for generic iOS platform; choose a specific platform or use atbin")
        }
    }

    var architecture: Architecture {
        switch(self) {
            case .OSX, .Linux:
                return Architecture.x86_64
            case .iOS(let arch):
                return arch
            case .iOSGeneric:
                fatalError("No architecture for generic iOS platform; choose a specific platform or use atbin")
        }
    }

    var dynamicLibraryExtension: String {
        switch(self) {
            case .OSX, .iOS, .iOSGeneric:
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

    ///If the platform is "virtual" (such as iOS), this returns all the sub-platforms.
    ///Otherwise, it returns the receiver
    public var allPlatforms: [Platform] {
        switch(self) {
            case .OSX, .Linux, .iOS:
            return [self]
            case .iOSGeneric:
            return [Platform.iOS(Architecture.x86_64), Platform.iOS(Architecture.i386), Platform.iOS(Architecture.armv7), Platform.iOS(Architecture.arm64)]
        }
    }

    var standardDeploymentTarget: String {
        switch(self) {
            case .OSX:
            return "10.12"
            case .Linux, .iOSGeneric:
            fatalError("Not implemented")

            case .iOS:
            if Platform.isXcode7 { return "9.3" }
            return "10.0"
        }
    }

    var nonDeploymentTargetTargetTriple: String {
        switch(self) {
            case .OSX:
            return "x86_64-apple-macosx"
            case .Linux, .iOSGeneric:
            fatalError("Not implemented")

            case .iOS(let arch):
            switch(arch) {
                case .x86_64:
                return "x86_64-apple-ios"
                case .i386:
                return "i386-apple-ios"
                case .arm64:
                return "arm64-apple-ios"
                case .armv7:
                return "armv7-apple-ios"
            }

        }
    }
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
            case .iOSGeneric:
            return "ios"
        }
    }
}

func findToolPath(toolName: String) -> Path {

    if Platform.buildPlatform == Platform.hostPlatform {
        //poke around on the filesystem
        //look in /usr/bin
        let usrBin = Path("\(Platform.toolchain!)/usr/bin/\(toolName)")
        if FS.fileExists(path: usrBin) { return usrBin }
        //look in /usr/local/bin
        let usrLocalBin = Path("\(Platform.toolchain!)/usr/local/bin/\(toolName)")
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
