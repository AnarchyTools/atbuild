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
 * Provides a setting for the default tool variables that should be used
 * within any given tool.
 */
public struct StandardizedToolPaths {
    private init() {}
    
    static private func join(base: String, _ paths: [String]) -> String {
        return paths.reduce(base) { $0 + StandardizedToolPaths.PathSeparator + $1 }
    }
    
    static private func join(base: String, _ paths: String...) -> String {
        return join(base, paths)
    }
    
    static private func cwd(paths: String...) -> String {
        return join(StandardizedToolPaths.CurrentDirectory, paths)
    }
    
    public static var PathSeparator: String {
        get { return "/" }
    }
    
    public static var CurrentDirectory: String {
        get {
            return NSFileManager.defaultManager().currentDirectoryPath
        }
    }
    public static var BuiltPath: String { get { return cwd("built") }}
    
    public static func ObjectsPath(task: String, profiles: String...) -> String {
        return StandardizedToolPaths.ObjectsPath(task, profiles: profiles)
    }
    public static func ObjectsPath(task: String, profiles: [String]) -> String {
        let name = profiles.count == 0 ? task : profiles.reduce(task) { $0 + "." + $1 }
        return join(StandardizedToolPaths.BuiltPath, "obj", name)
    }
    
    public static func BinariesPath(task: String, profiles: String...) -> String {
        return StandardizedToolPaths.BinariesPath(task, profiles: profiles)
    }
    public static func BinariesPath(task: String, profiles: [String]) -> String {
        let name = profiles.count == 0 ? task : profiles.reduce(task) { $0 + "." + $1 }
        return join(StandardizedToolPaths.BuiltPath, "bin", name)
    }
}

/** The builtin tools. */
let tools: [String:Tool] = [
    "shell": Shell(),
    "nop": Nop(),
    "xctestrun": XCTestRun(),
    "llbuild-build": SwiftBuildToolBuild(),
    "llbuild-config": SwiftBuildToolConfig(),
    "llbuild": SwiftBuildTool()
]

/**
 * A tool is a function that performs some operation, like building, or
 * running a shell command. We provide several builtin tools, but users
 * can build new ones out of the existing ones.
 */
public protocol Tool {
    func run(package: Package, task: ConfigMap)
}

/**
 * Look up a tool by name.
 */
func toolByName(name: String) -> Tool? {
    return tools[name]
}
