import Builder

class CrtCiPrepXCodebuild(Builder.Action):
    def run(self, env):
        env.shell.setenv("TEST_RUNNER_AWS_TESTING_STS_ROLE_ARN", env.shell.get_secret("aws-c-auth-testing/sts-role-arn"))
        actions = [
            Builder.SetupCrossCICrtEnvironment(use_xcodebuild=True)
        ]
        return Builder.Script(actions, name='crt-ci-prep-xcodebuild')
