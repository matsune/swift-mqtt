import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        return [
            testCase(MQTTTests.allTests),
            testCase(RemainLengthTests.allTests),
        ]
    }
#endif
