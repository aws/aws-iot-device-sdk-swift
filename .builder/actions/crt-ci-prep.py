import Builder

class CrtCiPrep(Builder.Action):
    def run(self, env):
        actions = [
            Builder.SetupCrossCICrtEnvironment()
        ]
        return Builder.Script(actions, name='crt-ci-prep')
