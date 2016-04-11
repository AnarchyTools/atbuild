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

import atpkg
import Foundation
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
    func run(task: Task) {
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
        let frameworkPath = "bin/\(name).framework"
        let manager = NSFileManager.defaultManager()
        let _ = try? manager.removeItem(atPath: frameworkPath)
        try! manager.createDirectory(atPath: frameworkPath, withIntermediateDirectories: false, attributes: nil)

        //'a' version
        let AVersionPath = "\(frameworkPath)/Versions/A"
        let relativeAVersionPath = "Versions/A"
        try! manager.createDirectory(atPath: AVersionPath, withIntermediateDirectories: true, attributes: nil)
        //'current' (produces code signing failures if absent)
        try! manager.createSymbolicLink(atPath: "\(frameworkPath)/Versions/Current", withDestinationPath: "A")

        //copy payload
        let payloadPath = task.importedPath + "bin/" + name + DynamicLibraryExtension
        print(payloadPath)
        try! manager.copyItemAtPath_SWIFTBUG(payloadPath, toPath: "\(AVersionPath)/\(name)")
        try! manager.createSymbolicLink(atPath: "\(frameworkPath)/\(name)", withDestinationPath: "\(relativeAVersionPath)/\(name)")

        //copy modules
        let modulePath = "\(AVersionPath)/Modules/\(name).swiftmodule"
        try! manager.createDirectory(atPath: modulePath, withIntermediateDirectories: true, attributes: nil)
        try! manager.copyItemAtPath_SWIFTBUG("bin/\(name).swiftmodule", toPath: "\(modulePath)/\(Architecture).swiftmodule")
        try! manager.copyItemAtPath_SWIFTBUG("bin/\(name).swiftdoc", toPath: "\(modulePath)/\(Architecture).swiftdoc")
        try! manager.createSymbolicLink(atPath: "\(frameworkPath)/Modules", withDestinationPath: "\(relativeAVersionPath)/Modules")

        //copy resources
        let resourcesPath = AVersionPath + "/Resources"
        try! manager.createDirectory(atPath: resourcesPath, withIntermediateDirectories: true, attributes: nil)
        for resource in resources {
            try! manager.copyItemAtPath_SWIFTBUG(task.importedPath + resource, toPath: "\(resourcesPath)/\(resource)")
        }
        try! manager.createSymbolicLink(atPath: "\(frameworkPath)/Resources", withDestinationPath: "\(relativeAVersionPath)/Resources")

        //codesign
        let cmd = "codesign --force --deep --sign - --timestamp=none \(AVersionPath)"
        print(cmd)
        if system(cmd) != 0 {
            fatalError("Codesign failed.")
        }
    }
}