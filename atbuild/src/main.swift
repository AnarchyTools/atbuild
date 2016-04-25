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

let version = "0.10.0"

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
    
    static var allOptions : [Options] { return [
        Overlay, 
        CustomFile, 
        Help, 
        Clean, 
        Toolchain, 
        Platform
        ] 
    }
}

let defaultPackageFile = Path("build.atpkg")

var focusOnTask : String? = nil

var packageFile = defaultPackageFile
var toolchain = Platform.buildPlatform.defaultToolchainPath
for (i, x) in Process.arguments.enumerated() {
    if x == Options.CustomFile.rawValue {
        packageFile = Path(Process.arguments[i+1])
    }
    if x == Options.Toolchain.rawValue {
        toolchain = Process.arguments[i+1]
        if toolchain == "xcode" {
            toolchain = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain"
        }
    }
    if x == Options.Platform.rawValue {
        let platformString = Process.arguments[i+1]
        Platform.targetPlatform = Platform(string: platformString)
    }
}

//build overlays
var overlays : [String] = []
for (i, x) in Process.arguments.enumerated() {
    if x == Options.Overlay.rawValue {
        let overlay = Process.arguments[i+1]
        overlays.append(overlay)
    }
}
overlays.append(contentsOf: Platform.targetPlatform.overlays)

print("enabling overlays \(overlays)")

var package: Package! = nil
do {
    package = try Package(filepath: packageFile, overlay: overlays, focusOnTask: focusOnTask)
} catch {
    fatalError("Could not load package file: \(error)")
}

//usage message
if Process.arguments.contains("--help") {
    print("atbuild - Anarchy Tools Build Tool \(version)")
    print("https://github.com/AnarchyTools")
    print("© 2016 Anarchy Tools Contributors.")
    print("")
    print("Usage:")
    print("atbuild [--toolchain (/toolchain/path | xcode)] [-f packagefile] [task] [--clean]")

    print("tasks:")
    for (key, task) in package.tasks {
        print("    \(key)")
    }
    exit(1)
}


func runTask(taskName: String, package: Package) {
    guard let task = package.tasks[taskName] else { fatalError("No \(taskName) task in build configuration.") }
    for task in package.prunedDependencyGraph(task: task) {
        TaskRunner.runTask(task: task, package: package, toolchain: toolchain)
    }
}

//choose which task to run
if Process.arguments.count > 1 {
    var i = 1
    while i < Process.arguments.count {
        let arg = Process.arguments[i]
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

print("Building package \(package.name)...")

runTask(taskName: focusOnTask!, package: package)

//success message
print("Built package \(package.name).")