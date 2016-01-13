guard let yamlContents = try? String(contentsOfFile: "atbuild.yaml") else { fatalError("Can't load atbuild.yaml") }
let yaml = Yaml.load(yamlContents)
guard let y = yaml.value else { fatalError("Can't parse YAML") }
guard let dict = y.dictionary else { fatalError("YAML doesnt define a dictionary") }
guard let package = dict["package"]?.dictionary else { fatalError("No package in YAML") }
guard let name = package["name"]?.string else { fatalError("No package name") }
print("Building task \(name)")