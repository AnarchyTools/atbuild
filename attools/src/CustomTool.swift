#if os(Linux)
import Glibc
#else
import Darwin
#endif

import atpkg
///Create a tool out of another program someone has lying around on their system
///Important: this is for programs that are written for AT.  For other programs, use shell instead.
final class CustomTool: Tool {
    static func isCustomTool(name: String) -> Bool {
        return name.hasSuffix(".attool")
    }
    let name: String
    init(name: String) {
        self.name = String(name.characters[name.characters.startIndex..<name.characters.index(name.characters.startIndex, offsetBy: name.characters.count - 7)])
    }
    func run(task: Task, toolchain: String) {
        var cmd = "\(self.name) "
        for key in task.allKeys.sorted() {
            if Task.Option.allOptions.map({$0.rawValue}).contains(key) { continue }
            guard let value = task[key]?.string else {
                fatalError("\(task.qualifiedName).\(key) is not string")
            }
            cmd += "--\(key) \"\(evaluateSubstitutions(input: value, package: task.package))\" "
        }
        Shell.environvironment(task: task) {
            anarchySystem(cmd)
        }
    }
}