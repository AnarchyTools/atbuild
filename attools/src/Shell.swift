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
import atpkg

/**
 * The shell tool forks a new process with `/bin/sh -c`. Any arguments specified
 * within the task will also be sent across.
 * If the tool returns with an error code of non-zero, the tool will fail.
 */
final class Shell : Tool {
    func run(task: Task, toolchain: String) {
        setenv("ATBUILD_USER_PATH", userPath(), 1)
        guard var script = task["script"]?.string else { fatalError("Invalid 'script' argument to shell tool.") }
        script = evaluateSubstitutions(input: script, package: task.package)
        do {
            let oldPath = NSFileManager.defaultManager().currentDirectoryPath
            defer { NSFileManager.defaultManager().changeCurrentDirectoryPath(oldPath) }

            NSFileManager.defaultManager().changeCurrentDirectoryPath(task.importedPath)

            if system("/bin/sh -c \"\(script)\"") != 0 {
                fatalError("/bin/sh -c \(script)")
            }
        }
    }
}