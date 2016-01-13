//  PlatformPaths.swift
//  © 2016 Anarchy Tools Contributors.
//  This file is part of atbuild.  It is subject to the license terms in the LICENSE
//  file found in the top level of this distribution
//  No part of atbuild, including this file, may be copied, modified,
//  propagated, or distributed except according to the terms contained
//  in the LICENSE file.

import Foundation

//todo, support multiple toolchains
#if os(OSX)
    let SDKPath = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk"
    let SwiftCPath = "/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin/swiftc"
    let SwiftBuildToolpath = "/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin/swift-build-tool"
#endif