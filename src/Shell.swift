import Foundation
final class Shell : Tool {
    func run(args: [Yaml: Yaml]) throws {
        guard let script = args["script"]?.string else { throw AnarchyBuildError.CantParseYaml("Invalid 'script' argument to shell tool.") }
        let t = NSTask.launchedTaskWithLaunchPath("/bin/sh", arguments: ["-c",script])
        t.waitUntilExit()
        if t.terminationStatus != 0 {
            throw AnarchyBuildError.ExternalToolFailed("/bin/sh -c \(script)")
        }
    }
}