import XCTest

import HTTP_CLIENTTests

var tests = [XCTestCaseEntry]()
tests += HTTP_CLIENTTests.allTests()
XCTMain(tests)