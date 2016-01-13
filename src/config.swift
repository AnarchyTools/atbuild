
func loadyaml() throws -> [Yaml:Yaml]  {
    guard let yamlContents = try? String(contentsOfFile: "atbuild.yaml") else { throw AnarchyBuildError.CantParseYaml("Can't load atbuild.yaml") }
    let yaml = Yaml.load(yamlContents)
    guard let y = yaml.value else { throw AnarchyBuildError.CantParseYaml("atbuild.yaml file didn't parse.") }
    guard let dict = y.dictionary else { fatalError("atbuild.yaml does not define a dictionary") }
    return dict
}

