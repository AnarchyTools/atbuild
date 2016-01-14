//  Task.swift
//  © 2016 Anarchy Tools Contributors.
//  This file is part of atbuild.  It is subject to the license terms in the LICENSE
//  file found in the top level of this distribution
//  No part of atbuild, including this file, may be copied, modified,
//  propagated, or distributed except according to the terms contained
//  in the LICENSE file.

///A Task is a CLI entry point to `atbuild`.  If you call `atbuild` with no arguments, we run a task called "default".
final class Task {
    let tool: String ///The tool that implements this task.  See Tools.swift
    let name: String ///The name of this task as it appears in the configuration file
    let yaml: [Yaml: Yaml] ///The full YAML description of the task
    
    init(yaml: [Yaml:Yaml], name: String) throws {
        self.yaml = yaml
        self.name = name
        guard let tool = yaml["tool"]?.string else {
            self.tool = "undefined"
            throw AnarchyBuildError.CantParseYaml("Missing task tool")
        }
        self.tool = tool
    }
    
    func run() throws {
        print("Running task \(name)...")
        let tool = try toolByName(self.tool)
        try tool.run(yaml)
        print("Completed task \(name).")
    }
}