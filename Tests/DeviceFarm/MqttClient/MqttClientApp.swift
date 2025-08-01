// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import SwiftUI

@main
struct MqttClientAppWrapper {
  static func main() {
    if #available(iOS 14.0, *) {
      MqttClientApp.main()
    } else {
      // The main actor only exists for 14.0 and above.
      UIApplicationMain(
        CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(SceneDelegate.self))
    }
  }
}

@available(iOS 14.0, *)
struct MqttClientApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?

  func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    let contentView = ContentView()

    // Use a UIHostingController as window root view controller.
    if let windowScene = scene as? UIWindowScene {
      let window = UIWindow(windowScene: windowScene)
      window.rootViewController = UIHostingController(rootView: contentView)
      self.window = window
      window.makeKeyAndVisible()
    }
  }
}
