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
    func run(task: Task) {
        guard let script = task["script"]?.string else { fatalError("Invalid 'script' argument to shell tool.") }
        let t = NSTask.launchedTaskWithLaunchPath("/bin/sh", arguments: ["-c", script])
        t.waitUntilExit()
        if t.terminationStatus != 0 {
            fatalError("/bin/sh -c \(script)")
        }
    }
}