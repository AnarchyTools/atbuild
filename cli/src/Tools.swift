//  Tools.swift
//  © 2016 Anarchy Tools Contributors.
//  This file is part of atbuild.  It is subject to the license terms in the LICENSE
//  file found in the top level of this distribution
//  No part of atbuild, including this file, may be copied, modified,
//  propagated, or distributed except according to the terms contained
//  in the LICENSE file.

///A tool is a function that performs some operation, like building, or running a shell command.
///We provide several builtin tools, but users can build new ones out of the existing ones.
protocol Tool {
    func run(args: [Yaml: Yaml]) throws
}

///The builtin tools.
let tools : [String: Tool] = ["shell":Shell(),"atllbuild":ATllbuild()]

///Look up a tool by name.  Throws if there is no such tool.
func toolByName(name: String) throws -> Tool {
    guard let tool = tools[name] else { throw AnarchyBuildError.CantParseYaml("Unknown build tool \(name)") }
    return tool
}
