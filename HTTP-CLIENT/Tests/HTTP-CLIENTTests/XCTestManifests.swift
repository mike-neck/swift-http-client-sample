import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(HTTP_CLIENTTests.allTests),
    ]
}
#endif