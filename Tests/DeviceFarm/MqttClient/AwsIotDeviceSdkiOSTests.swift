import AwsCommonRuntimeKit
import Foundation
import XCTest

@testable import AwsIotDeviceSdkSwift

class Mqtt5iOSTest: Mqtt5ClientTests {

  override func setUp() {
    super.setUp()
    self.isIOSDeviceFarm = true
  }
}
