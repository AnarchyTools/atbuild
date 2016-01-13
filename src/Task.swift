final class Task {
    let tool: String
    let name: String
    init(yaml: [Yaml:Yaml], name: String) throws {
        guard let tool = yaml["tool"]?.string else {
            self.tool = "undefined"
            self.name = name
            throw AnarchyBuildError.CantParseYaml("Missing task tool")
        }
        self.name = name
        self.tool = tool
    }
    
    func run() {
        print("Running task \(name)...")
    }
}