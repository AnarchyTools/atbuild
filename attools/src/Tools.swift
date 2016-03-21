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

/** The builtin tools. */
let tools: [String:Tool] = [
    "shell": Shell(),
    "atllbuild": ATllbuild(),
    "nop": Nop(),
    "xctestrun":XCTestRun()
]

/**
 * A tool is a function that performs some operation, like building, or
 * running a shell command. We provide several builtin tools, but users
 * can build new ones out of the existing ones.
 */
public protocol Tool {
    func run(task: Task)
}

/**
 * Look up a tool by name.
 */
func toolByName(name: String) -> Tool {
    guard let tool = tools[name] else { fatalError("Unknown build tool \(name)") }
    return tool
}

private var userPathCreated = false
/**Returns the "user" path.  This is a path that the user may use to store artifacts or for any other purposes.  This path is shared for all tasks built as part of the same `atbuild` invocation.
- postcondition: The path exists at this absolute locaton on disk.
- warning: This path is cleared between atbuild invocations. */
func userPath() -> String {
    let manager = NSFileManager.defaultManager()
    let userPath = manager.currentDirectoryPath + "/user"
    if !userPathCreated {
        let _ = try? manager.removeItem(atPath: userPath)
        try! manager.createDirectory(atPath: userPath, withIntermediateDirectories: false, attributes: nil)
        userPathCreated = true
    }
    return userPath
}
