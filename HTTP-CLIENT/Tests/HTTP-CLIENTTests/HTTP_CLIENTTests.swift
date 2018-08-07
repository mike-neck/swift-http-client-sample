import XCTest
@testable import HTTP_CLIENT

final class HTTP_CLIENTTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(HTTP_CLIENT().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
