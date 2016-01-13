protocol Tool {
    func run(args: [Yaml: Yaml]) throws
}

let tools : [String: Tool] = ["shell":Shell(),"atllbuild":ATllbuild()]

func toolByName(name: String) throws -> Tool {
    guard let tool = tools[name] else { throw AnarchyBuildError.CantParseYaml("Unknown build tool \(name)") }
    return tool
}
