//
//  PlatformPaths.swift
//  AnarchyToolsXcode
//
//  Created by Drew Crawford on 1/13/16.
//  Copyright © 2016 Drew Crawford. All rights reserved.
//

import Foundation

//todo, support multiple toolchains
#if os(OSX)
    let SDKPath = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk"
    let SwiftCPath = "/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin/swiftc"
    let SwiftBuildToolpath = "/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin/swift-build-tool"
#endif