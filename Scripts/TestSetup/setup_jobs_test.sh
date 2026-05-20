#!/bin/bash
# Creates AWS IoT resources needed for Jobs integration tests.
# Outputs: TEST_THING_NAME, TEST_JOB_ID, TEST_THING_GROUP_NAME as environment variables
# written to a file specified by $GITHUB_ENV (if set), or printed to stdout.

set -e

THING_GROUP_NAME="tgn_$(uuidgen | tr '[:upper:]' '[:lower:]')"
JOB_ID="$(uuidgen | tr '[:upper:]' '[:lower:]')"
THING_NAME="SwiftJobTest_$(uuidgen | tr '[:upper:]' '[:lower:]')"

echo "Creating thing group: $THING_GROUP_NAME"
aws iot create-thing-group --thing-group-name "$THING_GROUP_NAME" > /dev/null

THING_GROUP_ARN=$(aws iot describe-thing-group --thing-group-name "$THING_GROUP_NAME" --query thingGroupArn --output text)
echo "Thing group ARN: $THING_GROUP_ARN"

echo "Creating job: $JOB_ID"
aws iot create-job \
  --job-id "$JOB_ID" \
  --targets "$THING_GROUP_ARN" \
  --document '{"test":"do-something"}' \
  --target-selection CONTINUOUS > /dev/null

echo "Creating thing: $THING_NAME"
aws iot create-thing --thing-name "$THING_NAME" > /dev/null

echo "Adding thing to group"
aws iot add-thing-to-thing-group \
  --thing-group-name "$THING_GROUP_NAME" \
  --thing-name "$THING_NAME" > /dev/null

echo "Setup complete."

# Export to GitHub Actions environment if available, otherwise print
if [ -n "$GITHUB_ENV" ]; then
  echo "TEST_THING_NAME=$THING_NAME" >> "$GITHUB_ENV"
  echo "TEST_JOB_ID=$JOB_ID" >> "$GITHUB_ENV"
  echo "TEST_THING_GROUP_NAME=$THING_GROUP_NAME" >> "$GITHUB_ENV"
else
  echo "TEST_THING_NAME=$THING_NAME"
  echo "TEST_JOB_ID=$JOB_ID"
  echo "TEST_THING_GROUP_NAME=$THING_GROUP_NAME"
fi
