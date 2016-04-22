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

#if os(Linux)
import Glibc
#else
import Darwin
#endif

import atfoundation
import atpkg

private enum ModuleMapType: String {
    case Synthesized = "synthesized"
}

private enum Options: String {
    case Resources = "resources"
    case Headers = "headers"
    case ModuleMapType = "module-map-type"
    case Name = "name"
}

class PackageFramework: Tool {
    func compiler_crash() {
        #if !os(OSX)
        fatalError("packageframework is unsupported on this platform")
        #endif
    }
    func run(task: Task, toolchain: String) {
        compiler_crash() //work around a compiler crash

        guard let moduleMapType = task[Options.ModuleMapType.rawValue]?.string else {
            fatalError("Specify a \(Options.ModuleMapType.rawValue)")
        }
        guard let name = task[Options.Name.rawValue]?.string else {
            fatalError("Specify a \(Options.Name.rawValue)")
        }
        precondition(moduleMapType == ModuleMapType.Synthesized.rawValue, "Unknown \(Options.ModuleMapType.rawValue) \(moduleMapType)")

        guard let resourcesV = task[Options.Resources.rawValue]?.vector else {
            fatalError("Specify \(Options.Resources.rawValue).  This should contain at least an info plist.")
        }
        if resourcesV.count < 0 {
            fatalError("\(Options.Resources.rawValue) should contain an info plist.")
        }
        var resources: [String] = []
        for resource in resourcesV {
            guard let s = resource.string else { fatalError("Non-string resource \(resource)")}
            resources.append(s)
        }

        //rm framework if it exists
        let frameworkPath = Path("bin/\(name).framework")
        let _ = try? FS.removeItem(path: frameworkPath)
        try! FS.createDirectory(path: frameworkPath)

        //'a' version
        let relativeAVersionPath = Path("Versions/A")
        let AVersionPath = frameworkPath + relativeAVersionPath
        try! FS.createDirectory(path: AVersionPath, intermediate: true)
        //'current' (produces code signing failures if absent)
        try! FS.symlinkItem(from: frameworkPath + "Versions/Current", to: Path("A"))

        //copy payload
        let payloadPath = task.importedPath.appending("bin").appending(name + Platform.targetPlatform.dynamicLibraryExtension)
        print(payloadPath)
        try! FS.copyItem(from: payloadPath, to: AVersionPath.appending(name))
        try! FS.symlinkItem(from: frameworkPath.appending(name), to: relativeAVersionPath.appending(name))

        //copy modules
        let modulePath = AVersionPath.appending("Modules").appending(name + ".swiftmodule")
        try! FS.createDirectory(path: modulePath, intermediate: true)
        try! FS.copyItem(from: Path("bin/\(name).swiftmodule"), to: modulePath.appending(Platform.targetPlatform.architecture + ".swiftmodule"))
        try! FS.copyItem(from: Path("bin/\(name).swiftdoc"), to: modulePath.appending(Platform.targetPlatform.architecture + ".swiftdoc"))
        try! FS.symlinkItem(from: frameworkPath.appending("Modules"), to: relativeAVersionPath.appending("Modules"))

        //copy resources
        let resourcesPath = AVersionPath.appending("Resources")
        try! FS.createDirectory(path: resourcesPath, intermediate: true)
        for resource in resources {
            try! FS.copyItem(from: task.importedPath + resource, to: resourcesPath + resource)
        }
        try! FS.symlinkItem(from: frameworkPath + "Resources", to: relativeAVersionPath + "Resources")

        //codesign
        let cmd = "codesign --force --deep --sign - --timestamp=none '\(AVersionPath)'"
        print(cmd)
        if system(cmd) != 0 {
            fatalError("Codesign failed.")
        }
    }
}