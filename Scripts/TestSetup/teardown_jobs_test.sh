#!/bin/bash
# Cleans up AWS IoT resources created by setup_jobs_test.sh.
# Requires environment variables: TEST_THING_NAME, TEST_JOB_ID, TEST_THING_GROUP_NAME

set -e

if [ -n "$TEST_THING_GROUP_NAME" ]; then
  echo "Deleting thing group: $TEST_THING_GROUP_NAME"
  aws iot delete-thing-group --thing-group-name "$TEST_THING_GROUP_NAME" || echo "Warning: failed to delete thing group $TEST_THING_GROUP_NAME"
fi

if [ -n "$TEST_JOB_ID" ]; then
  echo "Deleting job: $TEST_JOB_ID"
  aws iot delete-job --job-id "$TEST_JOB_ID" --force || echo "Warning: failed to delete job $TEST_JOB_ID"
fi

if [ -n "$TEST_THING_NAME" ]; then
  echo "Deleting thing: $TEST_THING_NAME"
  aws iot delete-thing --thing-name "$TEST_THING_NAME" || echo "Warning: failed to delete thing $TEST_THING_NAME"
fi

echo "Teardown complete."
