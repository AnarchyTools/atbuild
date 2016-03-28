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

//todo, support multiple toolchains
#if os(OSX)
    let SDKPath = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk"
    let SwiftCPath = "/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin/swiftc"
    let SwiftBuildToolpath = "/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin/swift-build-tool"
    let DynamicLibraryExtension = ".dylib"
#elseif os(Linux)
    let SwiftCPath = "/usr/local/bin/swiftc"
    let SwiftBuildToolpath = "/usr/local/bin/swift-build-tool"
    let DynamicLibraryExtension = ".so"
#endif