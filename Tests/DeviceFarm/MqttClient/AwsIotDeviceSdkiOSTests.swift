import AwsCommonRuntimeKit
import Foundation
import XCTest

@testable import AwsIotDeviceSdkSwift

class Mqtt5iOSTest: Mqtt5ClientTests {

  private var _isIOSDeviceFarm: Bool = true

  override var isIOSDeviceFarm: Bool {
    get { return _isIOSDeviceFarm }
    set { _isIOSDeviceFarm = newValue }
  }

}
