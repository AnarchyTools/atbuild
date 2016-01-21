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

let version = "0.5.0-dev"

import Foundation
import atpkg
import attools

#if os(Linux)
//we need to get exit somehow
//https://bugs.swift.org/browse/SR-567
import Glibc
#endif

let defaultBuildFile = "build.atpkg"

func loadPackageFile() -> Package {

    //build overlays
    var overlays : [String] = []
    for (i, x) in Process.arguments.enumerate() {
        if x == "--overlay" {
            let overlay = Process.arguments[i+1]
            overlays.append(overlay)
        }
    }
    guard let package = try? Package(path: defaultBuildFile) else {
        print("Unable to load build file: \(defaultBuildFile)")
        exit(1)
    }
    
    return package
}

//usage message
if Process.arguments.contains("--help") {
    print("atbuild - Anarchy Tools Build Tool \(version)")
    print("https://github.com/AnarchyTools")
    print("© 2016 Anarchy Tools Contributors.")
    print("")
    print("Usage:")
    print("atbuild [task]")
    
    let package = loadPackageFile()
    print("tasks:")
    for (key, task) in package.tasks ?? ConfigMap() {
        print("    \(key)")
    } 
    exit(1)
}

let package = loadPackageFile()
print("Building package \(package.name)...")

func runtask(taskName: String, package: Package) throws {
//    for task in package.prunedDependencyGraph(task) {
        try TaskRunner.runTask(taskName, package: package)
//    }
}

//choose which task to run
var run = false
if Process.arguments.count > 1 {
    if !Process.arguments[1].hasPrefix("--") {
        run = true
        try runtask(Process.arguments[1], package: package)
    }
}
if !run {
    try runtask("default", package: package)
}

//success message
print("Built package \(package.name).")