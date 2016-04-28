// Copyright (c) 2016 Anarchy Tools Contributors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
import atpkg
import atfoundation

class PackageAtbin:Tool {
    private enum Options: String {
        case Name = "name"
        case Platforms = "platforms"
        case AtllbuildTask = "atllbuild-task"
    }

    func run(task: Task, toolchain: String) {

        guard let n_ = task[Options.Name.rawValue] else {
            fatalError("No \(Options.Name.rawValue) for \(task)")
        }
        guard case .StringLiteral(let name) = n_ else {
            fatalError("Non-string \(Options.Name.rawValue) for \(task)")
        }

        guard let t_ = task[Options.AtllbuildTask.rawValue] else {
            fatalError("No \(Options.AtllbuildTask.rawValue) for \(task)")
        }
        guard case .StringLiteral(let atllbuildTaskName) = t_ else {
            fatalError("Non-string \(Options.AtllbuildTask.rawValue) for \(task)")
        }
        guard let atllbuildTask = task.package.tasks[atllbuildTaskName]  else {
            fatalError("Unknown atllbuild task \(atllbuildTaskName) for \(task)")
        }

        //rm atbin if exists
        let atbinPath = Path("bin/\(name).atbin")
        let _ = try? FS.removeItem(path: atbinPath, recursive: true)
        try! FS.createDirectory(path: atbinPath, intermediate: true)

        //create working directory for lipo
        let workDir = Path(".atllbuild/lipo/")
        try! FS.createDirectory(path: workDir, intermediate: true)

        //restore old platform before leaving
        let oldPlatform = Platform.targetPlatform
        defer { Platform.targetPlatform = oldPlatform }

        guard case .some(.StringLiteral(let outputTypeString)) = atllbuildTask[ATllbuild.Options.OutputType.rawValue] else {
            fatalError("No \(ATllbuild.Options.OutputType.rawValue) for \(atllbuildTask) ")
        }

        guard let outputType = ATllbuild.OutputType(rawValue: outputTypeString) else {
            fatalError("Unknown \(ATllbuild.Options.OutputType.rawValue) \(outputTypeString)")
        }


        guard case .some(.StringLiteral(let outputName)) = atllbuildTask[ATllbuild.Options.Name.rawValue] else {
            fatalError("No \(ATllbuild.Options.Name.rawValue) for \(atllbuildTask)")
        }

        let payloadFileName: String
        switch(outputType) {
            case .DynamicLibrary:
            payloadFileName = "\(outputName)\(Platform.targetPlatform.dynamicLibraryExtension)"
            case .StaticLibrary:
            payloadFileName = "\(outputName).a"
            case .Executable:
            payloadFileName = outputName
        }

        guard case .some(.Vector(let platformArray)) = task[Options.Platforms.rawValue] else {
            fatalError("No \(Options.Platforms.rawValue) for \(task)")
        }

        var requestedBuildPlatforms : [String] = []
        for requestedPlatform in platformArray {
            guard case .StringLiteral(let p) = requestedPlatform else {
                fatalError("Non-string platform \(requestedPlatform)")
            }
            requestedBuildPlatforms.append(p)
        }

        let targetPlatforms: [Platform]
        if requestedBuildPlatforms == ["all"] {
            targetPlatforms = Platform.targetPlatform.allPlatforms
        }else {
            targetPlatforms = Platform.targetPlatform.allPlatforms.filter({requestedBuildPlatforms.contains($0.description)})
        } 

        if targetPlatforms.count == 0 {
            print("Warning: The intersection of \(requestedBuildPlatforms) and \(Platform.targetPlatform.allPlatforms) is the empty set; won't build atbin")
            return
        }
        //iterate through supported platforms
        for platform in targetPlatforms {
            Platform.targetPlatform = platform
            //run the underlying atbuild task
            TaskRunner.runTask(task: atllbuildTask, package: task.package, toolchain: toolchain, force: true)

            //copy payload to lipo location
            try! FS.copyItem(from: Path(".atllbuild/products/\(payloadFileName)"), to: workDir.join(Path("\(payloadFileName).\(Platform.targetPlatform)")))

            let modulePath = Path(".atllbuild/products/\(outputName).swiftmodule")
            if FS.fileExists(path: modulePath) {
                try! FS.copyItem(from: modulePath, to: atbinPath.join(Path("\(platform).swiftmodule")))
            }

            let docPath = Path(".atllbuild/products/\(outputName).swiftdoc")
            if FS.fileExists(path: docPath) {
                try! FS.copyItem(from: docPath, to: atbinPath.join(Path("\(platform).swiftdoc")))
            }

            let moduleMapPath = Path(".atllbuild/products/\(outputName).modulemap")
            if FS.fileExists(path: moduleMapPath) {
                try! FS.copyItem(from: moduleMapPath, to: atbinPath.join(Path("module.modulemap")))
            }
        }

        //lipo outputs
        switch(oldPlatform) {
            case .Linux:
            //no lipo, only one arch anyway
            try! FS.copyItem(from: workDir.join(Path("\(payloadFileName).\(Platform.targetPlatform)")), to: atbinPath.join(Path(payloadFileName)))

            case .OSX, .iOS, .iOSGeneric:
            var lipoCmd = "lipo -output bin/\(name).atbin/\(payloadFileName) -create "
            for platform in targetPlatforms {
                lipoCmd += "-arch \(platform.architecture) .atllbuild/lipo/\(payloadFileName).\(platform) "
            }
            if system(lipoCmd) != 0 {
                fatalError()
            }
        }

        //generate compiled.atpkg
        var s = ""
        s += "(package\n"
        s += ":name \"\(name)\"\n"
        s += ":payload \"\(payloadFileName)\"\n"
        s += ":platforms ["
        for platform in targetPlatforms {
            s += "\"\(platform)\" "
        }
        s += "]\n"
        s += ":type \"\(outputType.rawValue)\"\n"
        s += ")\n"
        try! s.write(to: atbinPath.join(Path("compiled.atpkg")))
    }
}