import XCTest
import UmbrellaHeader

class MyTest : XCTestCase {
    func testLoad() {

    }
}

XCTMain([MyTest()])

extension MyTest : XCTestCaseProvider {
var allTests : [(String, () throws -> Void)] {
    return [
    ("testLoad", testLoad)
    ]
}
}