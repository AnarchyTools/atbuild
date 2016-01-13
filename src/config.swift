//  config.swift
//  © 2016 Anarchy Tools Contributors.
//  This file is part of atbuild.  It is subject to the license terms in the LICENSE
//  file found in the top level of this distribution
//  No part of atbuild, including this file, may be copied, modified,
//  propagated, or distributed except according to the terms contained
//  in the LICENSE file.

///Load the contents of atbuild.yaml
func loadyaml() throws -> [Yaml:Yaml]  {
    guard let yamlContents = try? String(contentsOfFile: "atbuild.yaml") else { throw AnarchyBuildError.CantParseYaml("Can't load atbuild.yaml") }
    let yaml = Yaml.load(yamlContents)
    guard let y = yaml.value else { throw AnarchyBuildError.CantParseYaml("atbuild.yaml file didn't parse.") }
    guard let dict = y.dictionary else { fatalError("atbuild.yaml does not define a dictionary") }
    return dict
}

