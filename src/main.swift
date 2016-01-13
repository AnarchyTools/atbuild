//  main.swift
//  © 2016 Anarchy Tools Contributors.
//  This file is part of atbuild.  It is subject to the license terms in the LICENSE
//  file found in the top level of this distribution
//  No part of atbuild, including this file, may be copied, modified,
//  propagated, or distributed except according to the terms contained
//  in the LICENSE file.

let version = "0.1.0-dev"

import Foundation

//usage message
if Process.arguments.count > 1 && Process.arguments[1] == "--help" {
    print("atbuild - Anarchy Tools Build Tool \(version)")
    print("https://github.com/AnarchyTools")
    print("© 2016 Anarchy Tools Contributors.")
    print("")
    print("Usage:")
    print("atbuild [task]")
    if let yaml = try? loadyaml() {
        if let taskNames = yaml["tasks"]?.dictionary?.keys.map({$0.string!}) {
            print("    task: \(Array(taskNames)) ")
        }
    }
    
    exit(1)
}

//load configuration
let yaml = try! loadyaml()
guard let package = yaml["package"]?.dictionary else { fatalError("No package in YAML") }
guard let name = package["name"]?.string else { fatalError("No package name") }
print("Building package \(name)...")

func runtask(taskName: String) {
    guard let task = yaml["tasks"]?.dictionary else { fatalError("No tasks in YAML") }
    guard let defaultTask = task[Yaml(stringLiteral: taskName)]?.dictionary else { fatalError("No \(taskName) task in YAML") }
    let t = try! Task(yaml: defaultTask, name: taskName)
    try! t.run()
}

//choose which task to run
if Process.arguments.count > 1 {
    runtask(Process.arguments[1])
}
else {
    runtask("default")
}

//success message
print("Built package \(name).")