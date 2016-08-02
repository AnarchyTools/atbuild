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

    ///Builds the environment for the specified task.
    static func environment(task: Task) -> [String:String] {
        var environment: [String:String] = [:]
        environment["ATBUILD_PLATFORM"] = Platform.targetPlatform.description
        environment["ATBUILD_USER_PATH"] = userPath().description
        if let version = task.package.version {
            environment["ATBUILD_PACKAGE_VERSION"] = version
        }

        environment["ATBUILD_CONFIGURATION"] = "\(currentConfiguration)"
        if let o = currentConfiguration.optimize {
            environment["ATBUILD_CONFIGURATION_OPTIMIZE"] = o ? "1":"0"
        }
        if let o = currentConfiguration.fastCompile {
            environment["ATBUILD_CONFIGURATION_FAST_COMPILE"] = o ? "1":"0"
        }
        if let o = currentConfiguration.testingEnabled {
            environment["ATBUILD_CONFIGURATION_TESTING_ENABLED"] = o ? "1":"0"
        }
        if let o = currentConfiguration.noMagic {
            environment["ATBUILD_CONFIGURATION_NO_MAGIC"] = o ? "1":"0"
        }

        //expose debug configuration info
        let conf: String
        switch (currentConfiguration.debugInstrumentation) {
            case .Included:
            conf = "included"
            case .Omitted:
            conf = "omitted"
            case .Stripped:
            conf = "stripped"
        }
        environment["ATBUILD_CONFIGURATION_DEBUG_INSTRUMENTATION"] = conf

        //does bin path not exist?
        //let's create it!
        let binPath = try! FS.getWorkingDirectory().appending("bin")
        if !FS.fileExists(path: binPath) {
            try! FS.createDirectory(path: binPath)
        }
        environment["ATBUILD_BIN_PATH"] = binPath.description

        environment["PWD"]=String(validatingUTF8: realpath(task.importedPath.description,nil))!
        print("pwd set to",environment["PWD"])
        return environment
    }
    func run(task: Task) {
        guard var script = task["script"]?.string else { fatalError("Invalid 'script' argument to shell tool.") }
        script = evaluateSubstitutions(input: script, package: task.package)
        let env = Shell.environment(task: task)
        anarchySystem(script, environment: env)
    }
}