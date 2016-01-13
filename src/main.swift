guard let yamlContents = try? String(contentsOfFile: "atbuild.yaml") else { fatalError("Can't load atbuild.yaml") }
let yaml = Yaml.load(yamlContents)
guard let y = yaml.value else { fatalError("Can't parse YAML") }
guard let dict = y.dictionary else { fatalError("YAML doesnt define a dictionary") }
guard let package = dict["package"]?.dictionary else { fatalError("No package in YAML") }
guard let name = package["name"]?.string else { fatalError("No package name") }
print("Building package \(name)...")

//todo: run non-default tasks
guard let task = y.dictionary?["tasks"]?.dictionary else { fatalError("No tasks in YAML") }
guard let defaultTask = task["default"]?.dictionary else { fatalError("No default task in YAML") }
let t = try! Task(yaml: defaultTask, name: "default")
try! t.run()