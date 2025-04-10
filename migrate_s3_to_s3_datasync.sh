#!/bin/bash

# ------------------------------------------------------------------------------
# Script to create and start an AWS DataSync task to transfer data
# between two Amazon S3 buckets in potentially different AWS accounts.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# User-defined variables - MODIFY THESE VALUES
# ------------------------------------------------------------------------------

# Source S3 Bucket Information
SOURCE_BUCKET_ARN="arn:aws:s3:::your-source-splunk-bucket-name"
SOURCE_ACCOUNT_ID="your-source-aws-account-id"
SOURCE_DATASYNC_ROLE_ARN="arn:aws:iam::${SOURCE_ACCOUNT_ID}:role/your-source-datasync-role"
SOURCE_REGION="us-east-1" # Replace with the region of your source S3 bucket

# Destination S3 Bucket Information
DESTINATION_BUCKET_ARN="arn:aws:s3:::your-new-splunk-bucket-name"
DESTINATION_ACCOUNT_ID="your-destination-aws-account-id"
DESTINATION_DATASYNC_ROLE_ARN="arn:aws:iam::${DESTINATION_ACCOUNT_ID}:role/your-destination-datasync-role"
DESTINATION_REGION="us-west-2" # Replace with the region of your destination S3 bucket

# DataSync Task Configuration
DATASYNC_TASK_REGION="us-east-1" # Choose a region for the DataSync task (often source region)
BANDWIDTH_LIMIT="-1"           # -1 for no limit, or specify in bytes per second (e.g., 1048576 for 1MB/s)
EXCLUDE_PATTERNS=("splunk/db/*") # Array of patterns to exclude (optional)

# ------------------------------------------------------------------------------
# Helper function to execute AWS CLI commands and handle errors
# ------------------------------------------------------------------------------
execute_aws_cli() {
  local command="$1"
  echo "Executing: $command"
  if ! "$command"; then
    echo "Error executing command: $command"
    exit 1
  fi
}

# ------------------------------------------------------------------------------
# Create Source S3 Location
# ------------------------------------------------------------------------------
echo "--- Creating Source S3 Location ---"
SOURCE_LOCATION_OUTPUT=$(execute_aws_cli "aws datasync create-location-s3 \
  --s3-bucket-arn \"${SOURCE_BUCKET_ARN}\" \
  --s3-config BucketAccessRoleArn=\"${SOURCE_DATASYNC_ROLE_ARN}\" \
  --region \"${SOURCE_REGION}\" \
  --output text")

SOURCE_LOCATION_ARN=$(echo "$SOURCE_LOCATION_OUTPUT" | awk '{print $2}')
echo "Source S3 Location ARN: ${SOURCE_LOCATION_ARN}"

if [ -z "$SOURCE_LOCATION_ARN" ]; then
  echo "Failed to create Source S3 Location. Check the output for errors."
  exit 1
fi

# ------------------------------------------------------------------------------
# Create Destination S3 Location
# ------------------------------------------------------------------------------
echo "\n--- Creating Destination S3 Location ---"
DESTINATION_LOCATION_OUTPUT=$(execute_aws_cli "aws datasync create-location-s3 \
  --s3-bucket-arn \"${DESTINATION_BUCKET_ARN}\" \
  --s3-config BucketAccessRoleArn=\"${DESTINATION_DATASYNC_ROLE_ARN}\" \
  --region \"${DESTINATION_REGION}\" \
  --output text")

DESTINATION_LOCATION_ARN=$(echo "$DESTINATION_LOCATION_OUTPUT" | awk '{print $2}')
echo "Destination S3 Location ARN: ${DESTINATION_LOCATION_ARN}"

if [ -z "$DESTINATION_LOCATION_ARN" ]; then
  echo "Failed to create Destination S3 Location. Check the output for errors."
  exit 1
fi

# ------------------------------------------------------------------------------
# Create DataSync Task
# ------------------------------------------------------------------------------
echo "\n--- Creating DataSync Task ---"
CREATE_TASK_COMMAND="aws datasync create-task \
  --source-location-arn \"${SOURCE_LOCATION_ARN}\" \
  --destination-location-arn \"${DESTINATION_LOCATION_ARN}\" \
  --options BytesPerSecond=${BANDWIDTH_LIMIT}"

if [ ${#EXCLUDE_PATTERNS[@]} -gt 0 ]; then
  CREATE_TASK_COMMAND="${CREATE_TASK_COMMAND} --excludes "
  IFS=$','
  CREATE_TASK_COMMAND="${CREATE_TASK_COMMAND} \"Pattern=${EXCLUDE_PATTERNS[*]}\""
  unset IFS
fi

CREATE_TASK_OUTPUT=$(execute_aws_cli "${CREATE_TASK_COMMAND} --region \"${DATASYNC_TASK_REGION}\" --output text")

DATASYNC_TASK_ARN=$(echo "$CREATE_TASK_OUTPUT" | awk '{print $2}')
echo "DataSync Task ARN: ${DATASYNC_TASK_ARN}"

if [ -z "$DATASYNC_TASK_ARN" ]; then
  echo "Failed to create DataSync Task. Check the output for errors."
  exit 1
fi

# ------------------------------------------------------------------------------
# Start Task Execution
# ------------------------------------------------------------------------------
echo "\n--- Starting Task Execution ---"
START_EXECUTION_OUTPUT=$(execute_aws_cli "aws datasync start-task-execution \
  --task-arn \"${DATASYNC_TASK_ARN}\" \
  --region \"${DATASYNC_TASK_REGION}\" \
  --output text")

TASK_EXECUTION_ARN=$(echo "$START_EXECUTION_OUTPUT" | awk '{print $2}')
echo "Task Execution ARN: ${TASK_EXECUTION_ARN}"

if [ -z "$TASK_EXECUTION_ARN" ]; then
  echo "Failed to start Task Execution. Check the output for errors."
  exit 1
fi

echo "\n--- DataSync task initiated successfully. ---"
echo "You can monitor the task execution in the AWS Management Console or using the AWS CLI."

exit 0
