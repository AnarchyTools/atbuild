import XCTest
import UmbrellaHeader

class MyTest : XCTestCase {
    func testLoad() {

    }
}

extension MyTest  {
    static var allTests : [(String, MyTest -> () throws -> Void)] {
        return [
            ("testLoad", testLoad)
        ]
    }
}

XCTMain([testCase(MyTest.allTests)])

