"""
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: Apache-2.0.
"""
import pytest
from time import sleep

from appium import webdriver
from appium.options.ios import XCUITestOptions
from appium.webdriver.common.appiumby import AppiumBy
from selenium.common.exceptions import NoSuchElementException

capabilities = dict(
    platformName='ios',
    automationName='xcuitest',
    deviceName='iPhone',
    bundleId='aws-common-runtime.MqttClient',
    language='en',
    locale='US',
)

appium_server_url = 'http://0.0.0.0:4723/wd/hub'

class TestMqttIOS:
    def setup_method(self):
        self.driver = webdriver.Remote(appium_server_url, options=XCUITestOptions().load_capabilities(capabilities))
        self.driver.implicitly_wait(10)

    def teardown_method(self):
        if self.driver:
            self.driver.quit()

    @pytest.mark.parametrize("event_loop_tests", [
        "Background Process"
    ])

    def test_mqtt(self, event_loop_tests):
        sleep(3)
        self.perform_click_element('Setup Client and Start')
        # Sleep to make sure the connection is finished
        sleep(10)
        # put the application in background
        self.driver.background_app(-1)
        # Wait to see if the connection is interrupted
        sleep(15)

    def perform_click_element(self, element_id):
        try:
            element = self.driver.find_element(by=AppiumBy.ID, value=element_id)
            element.click()
            sleep(2)
        except NoSuchElementException:
            pytest.skip(f"Element with ID '{element_id}' not found. Skipped the test")

if __name__ == '__main__':
    TestMqttIOS.test_mqtt()
