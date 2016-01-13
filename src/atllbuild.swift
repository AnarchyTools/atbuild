import Foundation

final class ATllbuild : Tool {
    
    func collectSources(sourceDescriptions: [String]) -> [String] {
        var sources : [String] = []
        for description in sourceDescriptions {
            if description.hasSuffix("**.swift") {
                let basepath = String(Array(description.characters)[0..<description.characters.count - 9])
                let manager = NSFileManager.defaultManager()
                let enumerator = manager.enumeratorAtPath(basepath)!
                while let source = enumerator.nextObject() as? String {
                    if source.hasSuffix("swift") {
                        sources.append(source)
                    }
                }
            }
            else {
                sources.append(description)
            }
        }
        return sources
    }
    
    func run(args: [Yaml : Yaml]) throws {
        guard let sourceDescriptions = args["source"]?.array?.flatMap({$0.string}) else { throw AnarchyBuildError.CantParseYaml("Can't find sources for atllbuild.") }
        
        let sources = collectSources(sourceDescriptions)
        print("\(sources)")
    }
}