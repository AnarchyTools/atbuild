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

let version = "0.8.1"

import Foundation
import atpkg
import attools

enum Options: String {
    case Overlay = "--use-overlay"
    case CustomFile = "-f"
    case Help = "--help"
    case Clean = "--clean"
    
    static var allOptions : [Options] { return [Overlay, CustomFile] }
}

let defaultPackageFile = "build.atpkg"

var focusOnTask : String? = nil

//build overlays
var overlays : [String] = []
for (i, x) in Process.arguments.enumerated() {
    if x == Options.Overlay.rawValue {
        let overlay = Process.arguments[i+1]
        overlays.append(overlay)
    }
}
var packageFile = defaultPackageFile
for (i, x) in Process.arguments.enumerated() {
    if x == Options.CustomFile.rawValue {
        packageFile = Process.arguments[i+1]
    }
}
let package = try! Package(filepath: packageFile, overlay: overlays, focusOnTask: focusOnTask)

//usage message
if Process.arguments.contains("--help") {
    print("atbuild - Anarchy Tools Build Tool \(version)")
    print("https://github.com/AnarchyTools")
    print("© 2016 Anarchy Tools Contributors.")
    print("")
    print("Usage:")
    print("atbuild [-f packagefile] [task] [--clean]")
    
    print("tasks:")
    for (key, task) in package.tasks {
        print("    \(key)")
    } 
    exit(1)
}

func runTask(taskName: String, package: Package) {
    guard let task = package.tasks[taskName] else { fatalError("No \(taskName) task in build configuration.") }
    for task in package.prunedDependencyGraph(task) {
        TaskRunner.runTask(task, package: package)
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

runTask(focusOnTask!, package: package)

//success message
print("Built package \(package.name).")