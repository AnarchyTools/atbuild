final class Task {
    let tool: String
    let name: String
    let yaml: [Yaml: Yaml]
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