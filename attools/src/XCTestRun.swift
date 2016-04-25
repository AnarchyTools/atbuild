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

import atfoundation
import atpkg

class XCTestRun : Tool {
    enum Option: String {
        case TestExecutable = "test-executable"
    }

    func run(task: Task, toolchain: String) {
        guard let testExecutable = task[Option.TestExecutable.rawValue]?.string else {
            fatalError("No \(Option.TestExecutable.rawValue) for XCTestRun task \(task.qualifiedName)")
        }
        switch (Platform.targetPlatform) {
        case .OSX:
            do {
                let workingDirectory = try FS.temporaryDirectory(prefix: "XCTest-\(task)")

                let executablePath = workingDirectory + "XCTestRun.xctest/Contents/MacOS"
                try FS.createDirectory(path: executablePath, intermediate: true)
                try FS.copyItem(from: Path(testExecutable), to: executablePath.appending("XCTestRun"))
                var s = ""
                s += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
                s += "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
                s += "<plist version=\"1.0\">\n"
                s += "<dict>\n"
                s += "<key>CFBundleDevelopmentRegion</key>\n"
                s += "<string>en</string>\n"
                s += "<key>CFBundleExecutable</key>\n"
                s += "<string>XCTestRun</string>\n"
                s += "<key>CFBundleIdentifier</key>\n"
                s += "<string>org.swift.package-manager.dep-tests</string>\n"
                s += "<key>CFBundleInfoDictionaryVersion</key>\n"
                s += "<string>6.0</string>\n"
                s += "<key>CFBundleName</key>\n"
                s += "<string>NaOHTests</string>\n"
                s += "<key>CFBundlePackageType</key>\n"
                s += "<string>BNDL</string>\n"
                s += "<key>CFBundleShortVersionString</key>\n"
                s += "<string>1.0</string>\n"
                s += "<key>CFBundleSignature</key>\n"
                s += "<string>????</string>\n"
                s += "<key>CFBundleSupportedPlatforms</key>\n"
                s += "<array>\n"
                s += "<string>MacOSX</string>\n"
                s += "</array>\n"
                s += "<key>CFBundleVersion</key>\n"
                s += "<string>1</string>\n"
                s += "</dict>\n"
                s += "</plist>\n"
                try s.write(to: workingDirectory + "XCTestRun.xctest/Contents/Info.plist")
                anarchySystem("xcrun xctest \(workingDirectory)/XCTestRun.xctest")
            } catch {
                fatalError("Could not run XCTest: \(error)")
            }
            case .Linux:
            anarchySystem("\(testExecutable)")

			case .iOS:
            fatalError("XCTestRun is not supported for iOS")
        }
    }
}