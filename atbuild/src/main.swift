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

let version = "0.2.0-dev"

import Foundation
import atpkg
import attools

let defaultBuildFile = "build.atpkg"

func loadPackageFile() -> Package {
    guard let package = Package(filepath: defaultBuildFile) else {
        print("Unable to load build file: \(defaultBuildFile)")
        exit(1)
    }
    
    return package
}

//usage message
if Process.arguments.count > 1 && Process.arguments[1] == "--help" {
    print("atbuild - Anarchy Tools Build Tool \(version)")
    print("https://github.com/AnarchyTools")
    print("© 2016 Anarchy Tools Contributors.")
    print("")
    print("Usage:")
    print("atbuild [task]")
    
    let package = loadPackageFile()
    print("tasks:")
    for (key, task) in package.tasks {
        print("    \(key)")
    }
    
    exit(1)
}

let package = loadPackageFile()
print("Building package \(package.name)...")

func runtask(taskName: String) {
    guard let task = package.tasks[taskName] else { fatalError("No \(taskName) task in build configuration.") }
    TaskRunner.runTask(task, package: package)
}

//choose which task to run
if Process.arguments.count > 1 {
    runtask(Process.arguments[1])
}
else {
    runtask("default")
}

//success message
print("Built package \(package.name).")