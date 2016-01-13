guard let yamlContents = try? String(contentsOfFile: "atbuild.yaml") else { fatalError("Can't load atbuild.yaml") }
let yaml = Yaml.load(yamlContents)
guard let y = yaml.value else { fatalError("Can't parse YAML") }
guard let dict = y.dictionary else { fatalError("YAML doesnt define a dictionary") }
guard let package = dict["package"]?.dictionary else { fatalError("No package in YAML") }
guard let name = package["name"]?.string else { fatalError("No package name") }
print("Building package \(name)...")

func runtask(taskName: String) {
    guard let task = y.dictionary?["tasks"]?.dictionary else { fatalError("No tasks in YAML") }
    guard let defaultTask = task[Yaml(stringLiteral: taskName)]?.dictionary else { fatalError("No \(taskName) task in YAML") }
    let t = try! Task(yaml: defaultTask, name: taskName)
    try! t.run()
}

if Process.arguments.count > 1 {
    runtask(Process.arguments[1])
}
else {
    runtask("default")
}

print("Built package \(name).")