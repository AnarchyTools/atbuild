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

let version = "1.8.0"

import atfoundation
import atpkg
import attools

// This is a workaround for jumbled up output from print statements
setbuf(stdout, nil)

enum Options: String {
    case Overlay = "--use-overlay"
    case CustomFile = "-f"
    case Help = "--help"
    case Clean = "--clean"
    case Toolchain = "--toolchain"
    case Platform = "--platform"
    case Configuration = "--configuration"
    
    static var allOptions : [Options] { return [
        Overlay, 
        CustomFile, 
        Help, 
        Clean, 
        Toolchain, 
        Platform,
        Configuration
        ] 
    }
}

let defaultPackageFile = Path("build.atpkg")

var focusOnTask : String? = nil

var packageFile = defaultPackageFile
var toolchain = Platform.buildPlatform.defaultToolchainPath
for (i, x) in CommandLine.arguments.enumerated() {
    if x == Options.CustomFile.rawValue {
        packageFile = Path(CommandLine.arguments[i+1])
    }
    if x == Options.Toolchain.rawValue {
        toolchain = CommandLine.arguments[i+1]
        if toolchain == "xcode" {
            toolchain = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain"
        }
        else if toolchain == "xcode-beta" {
            toolchain = "/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain"
        }
    }
    if x == Options.Platform.rawValue {
        let platformString = CommandLine.arguments[i+1]
        Platform.targetPlatform = Platform(string: platformString)
    }
    if x == Options.Configuration.rawValue {
        let configurationString = CommandLine.arguments[i+1]
        currentConfiguration = Configuration(string: configurationString)
    }
}


//build overlays
var overlays : [String] = []
for (i, x) in CommandLine.arguments.enumerated() {
    if x == Options.Overlay.rawValue {
        let overlay = CommandLine.arguments[i+1]
        overlays.append(overlay)
    }
}
overlays.append(contentsOf: Platform.targetPlatform.overlays)

overlays.append("atbuild.configuration.\(currentConfiguration)")

print("enabling overlays \(overlays)")

var package: Package! = nil

func usage() {
    print("atbuild - Anarchy Tools Build Tool \(version)")
    print("https://github.com/AnarchyTools")
    print("© 2016 Anarchy Tools Contributors.")
    print("")
    print("Usage:")
    print("atbuild [--toolchain (/toolchain/path | xcode | xcode-beta )] [-f packagefile] [task] [--clean]")

    if let p = package {
        print("tasks:")
        for (key, _) in p.tasks {
            print("    \(key)")
        }
    }
    else {
        print("No tasks are available; run --help in a directory with a build.atpkg for project-specific help")
    }

    exit(1)
}

do {
    package = try Package(filepath: packageFile, overlay: overlays, focusOnTask: focusOnTask)
} catch {
    print("Could not load package file: \(error)")
    usage()
}

//usage message
if CommandLine.arguments.contains("--help") {
    usage()
}


func runTask(taskName: String, package: Package) {
    guard let task = package.tasks[taskName] else { fatalError("No \(taskName) task in build configuration.") }
    TaskRunner.runTask(task: task, package: package)
}


//choose which task to run
if CommandLine.arguments.count > 1 {
    var i = 1
    while i < CommandLine.arguments.count {
        let arg = CommandLine.arguments[i]
        if Options.allOptions.map({$0.rawValue}).contains(arg) {
            i += 1
        }
        else {
            focusOnTask = arg
            break
        }
        i += 1
    }
}
if focusOnTask == nil {
    focusOnTask = "default"
}

Platform.toolchain = toolchain

print("Building package \(package.name)...")

runTask(taskName: focusOnTask!, package: package)

//success message
print("Built package \(package.name).")