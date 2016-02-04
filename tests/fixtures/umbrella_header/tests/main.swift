import XCTest
import UmbrellaHeader

class MyTest : XCTestCase {
    func testLoad() {

    }
}

extension MyTest : XCTestCaseProvider {
var allTests : [(String, () throws -> Void)] {
    return [
    ("testLoad", testLoad)
    ]
}
}

XCTMain([MyTest()])

