//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation
import XCTest
import SignalCoreKit

class PromiseTests: XCTestCase {
    func test_simpleQueueChaining() {
        let guranteeExpectation = expectation(description: "Expect gurantee on global queue")
        let mapExpectation = expectation(description: "Expect map on global queue")
        let doneExpectation = expectation(description: "Expect done on global queue")

        var globalThread: Thread?
        Guarantee(on: .global()) { () -> String in
            assertOnQueue(.global())
            globalThread = Thread.current
            guranteeExpectation.fulfill()
            return "abc"
        }.map { string -> String in
            XCTAssertEqual(Thread.current, globalThread)
            mapExpectation.fulfill()
            return string + "xyz"
        }.done { string in
            XCTAssertEqual(Thread.current, globalThread)
            XCTAssertEqual(string, "abcxyz")
            doneExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func test_mixedQueueChaining() {
        let guranteeExpectation = expectation(description: "Expect gurantee on global queue")
        let mapExpectation = expectation(description: "Expect map on main queue")
        let doneExpectation = expectation(description: "Expect done on main queue")

        Guarantee(on: .global()) { () -> String in
            assertOnQueue(.global())
            guranteeExpectation.fulfill()
            return "abc"
        }.map(on: .main) { string -> String in
            XCTAssertTrue(Thread.isMainThread)
            mapExpectation.fulfill()
            return string + "xyz"
        }.done { string in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertEqual(string, "abcxyz")
            doneExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func test_queueChainingWithErrors() {
        let guranteeExpectation = expectation(description: "Expect gurantee on global queue")
        let mapExpectation = expectation(description: "Expect map on global queue")
        let catchExpectation = expectation(description: "Expect catch on main queue")

        enum SimpleError: String, Error {
            case assertion
        }

        var globalThread: Thread?
        Promise(on: .global()) { () -> String in
            assertOnQueue(.global())
            globalThread = Thread.current
            guranteeExpectation.fulfill()
            return "abc"
        }.map { _ -> String in
            XCTAssertEqual(Thread.current, globalThread)
            mapExpectation.fulfill()
            throw SimpleError.assertion
        }.done(on: .main) { _ in
            XCTAssert(false, "Done should never be called.")
        }.catch { error in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertEqual(error as? SimpleError, SimpleError.assertion)
            catchExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func test_recovery() {
        let doneExpectation = expectation(description: "Done")

        Promise(on: .global()) { () -> String in
            return "abc"
        }.map { _ -> String in
            throw OWSGenericError("some error")
        }.recover { _ in
            return "xyz"
        }.done { string in
            XCTAssertEqual(string, "xyz")
            doneExpectation.fulfill()
        }.catch { _ in
            XCTAssert(false, "Catch should never be called.")
        }

        waitForExpectations(timeout: 5)
    }

    func test_ensure() {
        let ensureExpectation1 = expectation(description: "ensure on success")
        let ensureExpectation2 = expectation(description: "ensure on failure")

        Promise(on: .global()) { () -> String in
            return "abc"
        }.map { _ -> String in
            throw OWSGenericError("some error")
        }.done { _ in
            XCTAssert(false, "Done should never be called.")
        }.ensure {
            ensureExpectation1.fulfill()
        }.catch { _ in
            XCTAssert(true, "Catch should be called.")
        }

        Promise(on: .global()) { () -> String in
            return "abc"
        }.map { string -> String in
            return string + "xyz"
        }.done { _ in
            XCTAssert(true, "Done should be called.")
        }.ensure {
            ensureExpectation2.fulfill()
        }.catch { _ in
            XCTAssert(false, "Catch should never be called.")
        }

        waitForExpectations(timeout: 5)
    }

    func test_whenFullfilled() {
        let when1 = expectation(description: "when1")
        let when2 = expectation(description: "when2")

        Promise.when(fullfilled: [
            Promise(on: .global()) { "abc" },
            Promise(on: .main) { "xyz" }.map { $0 + "abc" }
        ]).done {
            when1.fulfill()
        }.catch { _ in
            XCTAssert(false, "Catch should never be called.")
        }

        Promise.when(fullfilled: [
            Promise(on: .global()) { "abc" },
            Promise(on: .main) { "xyz" }.map { throw OWSGenericError("an error") }
        ]).done {
            XCTAssert(false, "Done should never be called.")
        }.catch { _ in
            when2.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func test_when() {
        let when1 = expectation(description: "when1")
        let when2 = expectation(description: "when2")

        var chainOneCounter = 0

        Promise.when(resolved: [
            Promise(onCurrent: .main) {
                chainOneCounter += 1
                throw OWSGenericError("error")
            },
            Promise(on: .global()) { () -> String in
                sleep(2)
                chainOneCounter += 1
                return "abc"
            }
        ]).done {
            XCTAssertEqual(chainOneCounter, 2)
            when1.fulfill()
        }

        var chainTwoCounter = 0

        Promise.when(fullfilled: [
            Promise(onCurrent: .main) {
                chainTwoCounter += 1
                throw OWSGenericError("error")
            },
            Promise(on: .global()) { () -> String in
                sleep(2)
                chainTwoCounter += 1
                return "abc"
            }
        ]).done {
            XCTAssert(false, "Done should never be called.")
        }.catch { _ in
            XCTAssertEqual(chainTwoCounter, 1)
            when2.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func test_wait() throws {
        XCTAssertEqual(try Promise(on: .global()) { () -> Int in
            sleep(1)
            return 5000
        }.wait(), 5000)

        XCTAssertThrowsError(try Promise(on: .global()) { () -> Int in
            sleep(1)
            throw OWSGenericError("An error")
        }.wait())
    }

    func test_timeout() {
        let expectTimeout = expectation(description: "timeout")

        Promise(on: .global()) { () -> String in
            sleep(15)
            return "default"
        }.timeout(
            seconds: 1,
            substituteValue: "substitute"
        ).done { result in
            XCTAssertEqual(result, "substitute")
            expectTimeout.fulfill()
        }

        let expectNoTimeout = expectation(description: "noTimeout")

        Promise(on: .global()) { () -> String in
            sleep(1)
            return "default"
        }.timeout(
            seconds: 3,
            substituteValue: "substitute"
        ).done { result in
            XCTAssertEqual(result, "default")
            expectNoTimeout.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func test_anyPromise() {
        let anyPromiseExpectation = expectation(description: "Expect anyPromise on global queue")
        let mapExpectation = expectation(description: "Expect map on global queue")
        let doneExpectation = expectation(description: "Expect done on global queue")

        var globalThread: Thread?
        AnyPromise(Promise(on: .global()) { () -> String in
            assertOnQueue(.global())
            globalThread = Thread.current
            anyPromiseExpectation.fulfill()
            return "abc"
        }).map { string -> String in
            XCTAssertTrue(string is String)
            XCTAssertEqual(Thread.current, globalThread)
            mapExpectation.fulfill()
            return (string as! String) + "xyz"
        }.done { string in
            XCTAssertEqual(Thread.current, globalThread)
            XCTAssertEqual(string, "abcxyz")
            doneExpectation.fulfill()
        }.cauterize()

        waitForExpectations(timeout: 5)
    }
}
