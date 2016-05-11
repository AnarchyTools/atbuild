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

/**
 * The shell tool forks a new process with `/bin/sh -c`. Any arguments specified
 * within the task will also be sent across.
 * If the tool returns with an error code of non-zero, the tool will fail.
 */
final class Shell : Tool {

    ///Sets the environment for the specified task.
    static func environvironment(task: Task, block: () -> ()) {
        setenv("ATBUILD_PLATFORM", "\(Platform.targetPlatform)", 1)
        setenv("ATBUILD_USER_PATH", userPath().description, 1)
        if let version = task.package.version {
            setenv("ATBUILD_PACKAGE_VERSION", version, 1)
        }

        //does bin path not exist?
        //let's create it!
        let binPath = try! FS.getWorkingDirectory().appending("bin")
        if !FS.fileExists(path: binPath) {
            try! FS.createDirectory(path: binPath)
        }
        setenv("ATBUILD_BIN_PATH",binPath.description,1)

        //deal with directory nonsense
        let oldPath = try! FS.getWorkingDirectory()
        defer {
            do {
                try FS.changeWorkingDirectory(path: oldPath)
            } catch {
                print("Can not revert to previous working directory '\(oldPath)': \(error)")
                exit(42)
            }
        }
        do {
            try FS.changeWorkingDirectory(path: task.importedPath)
        }
        catch {
            print("Cannot change working directory to \(task.importedPath)")
        }
        block()
    }
    func run(task: Task, toolchain: String) {
        guard var script = task["script"]?.string else { fatalError("Invalid 'script' argument to shell tool.") }
        script = evaluateSubstitutions(input: script, package: task.package)
        Shell.environvironment(task: task) {
            anarchySystem(script)
        }
    }
}