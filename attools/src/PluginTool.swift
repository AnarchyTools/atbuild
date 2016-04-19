#if os(Linux)
import Glibc
#else
import Darwin
#endif

import atpkg
///Create a tool out of another program someone has lying around on their system
final class PluginTool: Tool {
    static func isPlugin(name: String) -> Bool {
        return name.hasSuffix(".plugin")
    }
    let pluginName: String
    init(pluginName: String) {
        self.pluginName = String(pluginName.characters[pluginName.characters.startIndex..<pluginName.characters.startIndex.advanced(by: pluginName.characters.count - 7)])
    }
    func run(task: Task, toolchain: String) {
        var cmd = "\(self.pluginName) "
        for key in task.allKeys.sorted() {
            if Task.Option.allOptions.map({$0.rawValue}).contains(key) { continue }
            guard let value = task[key]?.string else {
                fatalError("\(task.qualifiedName).\(key) is not string")
            }
            cmd += "--\(key) \"\(evaluateSubstitutions(input: value, package: task.package))\" "
        }
        setenv("ATBUILD_USER_PATH", userPath(), 1)
        anarchySystem(cmd)
    }
}