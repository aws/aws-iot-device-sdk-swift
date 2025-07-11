import Builder
import os
import sys

class XCodeTests(Builder.Action):
    def run(self, env):
        destination = env.shell.getenv("XCODE_DESTINATION")
        commands =[
            'xcodebuild',
            '-scheme',
            'AwsIotDeviceSdkSwift-Package',
            'test',
            '-destination',
            "platform={}".format(destination)
        ]
        env.shell.exec(commands, check=True)
