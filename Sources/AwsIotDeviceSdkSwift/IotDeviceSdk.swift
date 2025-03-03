///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

@_exported import AwsCommonRuntimeKit

/**
 * Initializes the library.
 * `IotDeviceSdk.initialize` must be called before using any other functionality.
 */
public struct IotDeviceSdk {

    /// Initializes the library.
    /// Must be called before using any other functionality.
    public static func initialize() {
        CommonRuntimeKit.initialize()
    }

    /**
     * This is an optional cleanup function which will block until all the SDK resources have cleaned up.
     * Use this function only if you want to make sure that there are no memory leaks at the end of the application.
     * Warning: It will hang if you are still holding references to any SDK objects such as HostResolver.
     */
    public static func cleanUp() {
        CommonRuntimeKit.cleanUp()
    }

    private init () {}
}