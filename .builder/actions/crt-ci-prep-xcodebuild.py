import Builder

class CrtCiPrepXCodebuild(Builder.Action):
    def run(self, env):
        actions = [
            Builder.SetupCrossCICrtEnvironment(use_xcodebuild=True)
        ]
        return Builder.Script(actions, name='crt-ci-prep-xcodebuild')
