//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import AwsCommonRuntimeKit
@testable import AwsIotDeviceSdkSwift

class XCBaseTestCase: XCTestCase {
    override func setUp() {
        super.setUp()
        // XCode currently lacks a way to enable logs exclusively for failed tests only.
        // To prevent log spamming, we use `error` log level to only print error message.
        // We should update this once a more efficient log processing method becomes available.
        try? Logger.initialize(target: .standardOutput, level: .error)

        CommonRuntimeKit.initialize()
    }

    override func tearDown() {
        CommonRuntimeKit.cleanUp()
        super.tearDown()
    }
}


extension XCTestCase {
    func skipTest(message: String) throws {
       throw XCTSkip(message)
    }

    func skipIfiOS() throws {
        #if os(iOS)
            throw XCTSkip("Skipping test on iOS")
        #endif
    }

    func skipifmacOS() throws {
        #if os(macOS)
            throw XCTSkip("Skipping test on macOS")
        #endif
    }

    func skipIfLinux() throws {
        #if os(Linux)
            throw XCTSkip("Skipping test on linux")
        #endif
    }

    func skipIfwatchOS() throws {
        #if os(watchOS)
            throw XCTSkip("Skipping test on watchOS")
        #endif
    }

    func skipIftvOS() throws {
        #if os(tvOS)
            throw XCTSkip("Skipping test on tvOS")
        #endif
    }

    // func skipIfPlatformDoesntSupportTLS() throws {
    //     try skipIfiOS()
    //     try skipIfwatchOS()
    //     try skipIftvOS()
    // }

    /// Return the environment variable value, or Skip the test if env var is not set.
    func getEnvironmentVarOrSkipTest(environmentVarName name: String) throws -> String {
        guard let result = ProcessInfo.processInfo.environment[name] else {
            throw XCTSkip("Skipping test because required environment variable \(name) is missing.")
        }
        return result
    }
}
