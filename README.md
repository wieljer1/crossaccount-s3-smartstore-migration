# splunk-smartstore-migration

[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

This repository contains scripts and documentation related to the migration of a large Splunk SmartStore cluster from one Amazon S3 SmartStore cloud environment to a new one. The primary focus is on automating the data transfer using AWS DataSync.

## Contents

This repository includes:

* **`migrate_s3_smartstore.sh`:** A Bash script that uses the AWS CLI to manage the creation and execution of an AWS DataSync task for transferring data between S3 buckets.
* **`README.md`:** This file, providing an overview of the repository and details on the script.

## Getting Started

These instructions will help you understand the structure and use of the contents in this repository.

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd splunk-smartstore-migration
    ```

2.  **Explore the contents:** Review the `migrate_s3_smartstore.sh` script to understand its functionality.

## Usage

The `migrate_s3_smartstore.sh` script is designed to automate the creation and execution of an AWS DataSync task to transfer data between your source and destination S3 buckets.

**Key Sections of the Script:**

* **Create Source S3 Location:**
    ```bash
    aws datasync create-location-s3 \
        --s3-bucket-arn "arn:aws:s3:::your-source-splunk-bucket-name" \
        --s3-config BucketAccessRoleArn="arn:aws:iam::your-source-aws-account-id:role/your-source-datasync-role" \
        --region us-east-1
    ```
    This section uses the `aws datasync create-location-s3` command to define the source Amazon S3 bucket for the DataSync task.
    * `--s3-bucket-arn`: Specifies the Amazon Resource Name (ARN) of your source S3 bucket.
    * `--s3-config BucketAccessRoleArn`: Defines the ARN of the IAM role within your source AWS account that DataSync will assume to access the source S3 bucket. This role needs permissions like `s3:ListBucket` and `s3:GetObject`.
    * `--region`: Indicates the AWS region where your source S3 bucket is located.

* **Create Destination S3 Location:**
    ```bash
    aws datasync create-location-s3 \
        --s3-bucket-arn "arn:aws:s3:::your-new-splunk-bucket-name" \
        --s3-config BucketAccessRoleArn="arn:aws:iam::your-destination-aws-account-id:role/your-destination-datasync-role" \
        --region us-west-2
    ```
    This section uses the `aws datasync create-location-s3` command to define the destination Amazon S3 bucket for the DataSync task.
    * `--s3-bucket-arn`: Specifies the ARN of your destination S3 bucket.
    * `--s3-config BucketAccessRoleArn`: Defines the ARN of the IAM role within your destination AWS account that DataSync will assume to access the destination S3 bucket. This role needs permissions like `s3:ListBucket`, `s3:PutObject`, and potentially `s3:DeleteObject` if synchronization is involved.
    * `--region`: Indicates the AWS region where your destination S3 bucket is located.

* **Create DataSync Task:**
    ```bash
    aws datasync create-task \
        --source-location-arn "arn:aws:datasync:us-east-1:source-account-id:location/loc-xxxxxxxxxxxxxxxxx"
        --destination-location-arn "arn:aws:datasync:us-west-2:new-account-id:location/loc-yyyyyyyyyyyyyyyyy"
        --options BytesPerSecond=-1
        --excludes Pattern="splunk/db/*"
        --region us-east-1
    ```
    This section uses the `aws datasync create-task` command to create the DataSync task that orchestrates the data transfer.
    * `--source-location-arn`: The ARN of the source S3 location created in the previous step.
    * `--destination-location-arn`: The ARN of the destination S3 location created in the previous step.
    * `--options BytesPerSecond=-1`: Sets the bandwidth limit for the transfer. `-1` indicates no limit. Adjust as needed.
    * `--excludes Pattern="splunk/db/*"`: An optional parameter to exclude specific file patterns from the transfer. In this example, it excludes Splunk's local database files, which are typically not needed in a SmartStore migration. Modify this based on your requirements.
    * `--region`: The AWS region where the DataSync task will be created. It's often recommended to choose a region close to your source data for better performance.

* **Start Task Execution:**
    ```bash
    aws datasync start-task-execution \
        --task-arn "arn:aws:datasync:us-east-1:source-account-id:task/task-zzzzzzzzzzzzzzzzz"
        --region us-east-1
    ```
    This section uses the `aws datasync start-task-execution` command to initiate the data transfer process defined by the created DataSync task.
    * `--task-arn`: The ARN of the DataSync task created in the previous step.
    * `--region`: The AWS region where the DataSync task resides.

**Key Considerations:**

* **IAM Roles:** Ensure you have created and configured appropriate IAM roles in both your source and destination AWS accounts. These roles must grant DataSync the necessary permissions to access the respective S3 buckets. The `BucketAccessRoleArn` parameters in the `create-location-s3` commands specify these roles.
* **Cross-Account Access:** If your source and destination S3 buckets are in different AWS accounts, the IAM role in the destination account must have a trust policy that allows the DataSync service (or the specific IAM role used by DataSync) in the source account to assume it.
* **Region Selection:** Carefully choose the AWS region for your DataSync task. Placing it in or near the region of your source data can significantly improve transfer performance.
* **Task Options:** Review the various `--options` available with the `aws datasync create-task` command to customize the transfer behavior, such as overwrite rules and data verification settings.
* **Excludes/Includes:** Use the `--excludes` and `--includes` parameters in the `aws datasync create-task` command to fine-tune which data is transferred. For a complete SmartStore migration, you might initially want to transfer all data.
* **Monitoring:** After starting the task execution, you can monitor the progress and status of your DataSync task in the AWS Management Console or by using the `aws datasync list-task-executions` and `aws datasync describe-task-execution` CLI commands.

## Contributing

Contributions are welcome. Please follow these guidelines:
1.  Fork the repository.
2.  Create a new branch for your feature or bug fix.
3.  Make your changes.
4.  Commit your changes.
5.  Push to the branch.
6.  Create a pull request.

## License

[MIT](https://opensource.org/licenses/MIT)

## Contact

[Your Name/Team Name] - [Your Email Address (Optional)]
