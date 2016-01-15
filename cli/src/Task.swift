//  Task.swift
//  © 2016 Anarchy Tools Contributors.
//  This file is part of atbuild.  It is subject to the license terms in the LICENSE
//  file found in the top level of this distribution
//  No part of atbuild, including this file, may be copied, modified,
//  propagated, or distributed except according to the terms contained
//  in the LICENSE file.

#if ATBUILD
import yaml
#endif

///A Task is a CLI entry point to `atbuild`.  If you call `atbuild` with no arguments, we run a task called "default".
final class Task {
    let tool: String ///The tool that implements this task.  See Tools.swift
    let name: String ///The name of this task as it appears in the configuration file
    let dependencies: [String:[Yaml:Yaml]]
    let yaml: [Yaml: Yaml] ///The full YAML description of the task
    let entireConfig: [Yaml: Yaml] ///The entire configuration of the package
    
    init(yaml: [Yaml:Yaml], name: String, entireConfig: [Yaml: Yaml]) throws {
        self.entireConfig = entireConfig
        self.yaml = yaml
        self.name = name
        guard let tool = yaml["tool"]?.string else {
            self.tool = "undefined"
            dependencies = [:]
            throw AnarchyBuildError.CantParseYaml("Missing task tool")
        }
        self.tool = tool
        if let d = yaml["dependency"]?.array {
            var newdeps : [String: [Yaml:Yaml]] = [:]
            for dep in d {
                guard let depname = dep.string else {
                    dependencies = [:]
                    throw AnarchyBuildError.CantParseYaml("\(dep) is not a string")
                }
                guard let depden = entireConfig["tasks"]?.dictionary?[Yaml(stringLiteral: depname)]?.dictionary else {
                    dependencies = [:]
                    throw AnarchyBuildError.CantParseYaml("Trouble loading dependent task \(depname)")
                }
                
                newdeps[depname] = depden
            }
            dependencies = newdeps
        }
        else { dependencies = [:] }
    }
    
    func run() throws {
        for dependency in dependencies.keys {
            let t = try Task(yaml: dependencies[dependency]!, name: dependency, entireConfig: entireConfig)
            try t.run()
        }
        print("Running task \(name)...")
        let tool = try toolByName(self.tool)
        try tool.run(yaml)
        print("Completed task \(name).")
    }
}