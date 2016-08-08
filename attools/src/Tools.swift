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

/** The builtin tools. */
let tools: [String:Tool] = [
    "shell": Shell(),
    "atllbuild": ATllbuild(),
    "nop": Nop(),
    "xctestrun":XCTestRun(),
    "packageframework":PackageFramework(),
    "packageatbin":PackageAtbin()
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
    if CustomTool.isCustomTool(name: name) {
        return CustomTool(name: name)
    }
    guard let tool = tools[name] else { fatalError("Unknown build tool \(name)") }
    return tool
}

private var userPathCreated = false
/**Returns the "user" path.  This is a path that the user may use to store artifacts or for any other purposes.  This path is shared for all tasks built as part of the same `atbuild` invocation.
- postcondition: The path exists at this absolute locaton on disk.
- warning: This path is cleared between atbuild invocations. */
func userPath() -> Path {
    do {
        let userPath = try FS.getWorkingDirectory().appending("user")
        if !userPathCreated {
            if FS.isDirectory(path: userPath) {
                try FS.removeItem(path: userPath, recursive: true)
            }
            try FS.createDirectory(path: userPath)
            userPathCreated = true
        }
        return userPath
    } catch {
        fatalError("Could not create user dir: \(error)")
    }
}

private func _WSTATUS(_ status: CInt) -> CInt {
    return status & 0x7f
}

private func WIFEXITED(_ status: CInt) -> Bool {
    return _WSTATUS(status) == 0
}

private func WEXITSTATUS(_ status: CInt) -> CInt {
    return (status >> 8) & 0xff
}

/// convenience wrapper for waitpid
func waitpid(_ pid: pid_t) -> Int32 {
    while true {
        var exitStatus: Int32 = 0
        let rv = waitpid(pid, &exitStatus, 0)

        if rv != -1 {
            if WIFEXITED(exitStatus) {
                return WEXITSTATUS(exitStatus)
            } else {
                fatalError("Exit signal")
            }
        } else if errno == EINTR {
            continue  // see: man waitpid
        } else {
            fatalError("waitpid: \(errno)")
        }
    }
}

///A wrapper for POSIX "system" call.
///If return value is non-zero, we exit (not fatalError)
///See #72 for details.
///- note: This function call is appropriate for commands that are user-perceivable (such as compilation)
///Rather than calls that aren't
func anarchySystem(_ cmd: String, environment: [String: String]) {
    var pid : pid_t = 0
    //copy PATH
    let path = getenv("PATH")!
    var environment = environment
    environment["PATH"] = String(validatingUTF8: path)!

    let args: [String] =  ["sh","-c",cmd]
    let argv = args.map{ $0.withCString(strdup) }
    let env: [UnsafeMutablePointer<CChar>?] = environment.map{ "\($0.0)=\($0.1)".withCString(strdup) }
    
    let directory = try! FS.getWorkingDirectory()
    defer {try! FS.changeWorkingDirectory(path: directory)}
    if let e = environment["PWD"] {
        try! FS.changeWorkingDirectory(path: Path(environment["PWD"]!))
    }
    let status = posix_spawn(&pid, "/bin/sh",nil,nil,argv + [nil],env + [nil])


    if status != 0 {
        fatalError("spawn error \(status)")
    }

    let returnCode = try! waitpid(pid)
    if returnCode != 0 {
        fatalError("process \(cmd) error \(returnCode)")
    }
}