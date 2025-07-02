import argparse
import sys
import os
import time
import datetime

import requests # - for uploading files
import boto3

parser = argparse.ArgumentParser(description="Utility script to upload and run Device tests on AWS Device Farm for CI")
parser.add_argument('--run_id', required=True, help="A unique number for each workflow run within a repository")
parser.add_argument('--run_attempt', required=True, help="A unique number for each attempt of a particular workflow run in a repository")
parser.add_argument('--project_arn', required=True, help="Arn for the Device Farm Project the apk will be tested on")
parser.add_argument('--device_pool_arn', required=True, help="Arn for device pool of the Device Farm Project the apk will be tested on")
parser.add_argument('--test_file_path', required=True, help="Path to the zip files that contains test scripts to upload to device farm")
parser.add_argument('--app_file_path', required=True, help="Path to the executable .app file")

def upload_file(client, projectArn, unique_prefix, filepath, _type):
    filename = os.path.basename(filepath)
    print('Upload file name: ' + unique_prefix + "_" + filename)
    response = client.create_upload(projectArn=projectArn,
                                    name=unique_prefix+"_"+filename,
                                    type=_type
                                    )
    # Get the upload ARN, which we'll return later.
    upload_arn = response['upload']['arn']
    # We're going to extract the URL of the upload and use Requests to upload it
    upload_url = response['upload']['url']
    with open(filepath, 'rb') as file_stream:
        print(f"Uploading {filepath} to Device Farm as {response['upload']['name']}... ", end='')
        put_req = requests.put(upload_url, data=file_stream)
        print('File upload status code: ' + str(put_req.status_code) + ' reason: ' + put_req.reason)
        if not put_req.ok:
            raise Exception("Couldn't upload, requests said we're not ok. Requests says: " + put_req.reason)
    started = datetime.datetime.now()
    device_farm_upload_status = client.get_upload(arn=upload_arn)
    while device_farm_upload_status['upload']['status'] != 'SUCCEEDED':
        print(f"Upload of {filename} in state {response['upload']['status']} after " + str(
            datetime.datetime.now() - started))
        if device_farm_upload_status['upload']['status'] == 'FAILED':
            print('File upload failed with message: ' + str(device_farm_upload_status['upload']['message']))
            print('Upload failed to process')
            sys.exit(-1)
        time.sleep(1)
        device_farm_upload_status = client.get_upload(arn=upload_arn)

    return upload_arn


def main():
    args = parser.parse_args()
    run_id = args.run_id
    run_attempt = args.run_attempt
    project_arn = args.project_arn
    device_pool_arn = args.device_pool_arn
    # test_spec_file_path = args.test_spec_file_path
    test_file_path = args.test_file_path
    app_file_path = args.app_file_path

    region = os.getenv('AWS_DEVICE_FARM_REGION')

    print("Beginning Device Farm Setup \n")

    # Create Boto3 client for Device Farm
    try:
        client = boto3.client('devicefarm', region_name=region)
    except Exception:
        print("Error - could not make Boto3 client. Credentials likely could not be sourced")
        sys.exit(-1)
    print("Boto3 client established")

    # Upload the crt library shell app to Device Farm
    unique_prefix = 'CI-' + run_id + '-' + run_attempt
    device_farm_app_upload_arn = upload_file(client, project_arn, unique_prefix, app_file_path, 'IOS_APP')
    device_farm_test_upload_arn = upload_file(client, project_arn, unique_prefix, test_file_path, 'XCTEST_TEST_PACKAGE')
    # device_farm_test_spec_upload_arn = upload_file(client, project_arn, unique_prefix, test_spec_file_path, 'INSTRUMENTATION_TEST_SPEC')

    print('scheduling run')
    schedule_run_response = client.schedule_run(
        projectArn=project_arn,
        appArn=device_farm_app_upload_arn,
        devicePoolArn=device_pool_arn,
        name=unique_prefix,
        test={
            "type": "XCTEST",
            "testPackageArn": device_farm_test_upload_arn
        },
        executionConfiguration={
            'jobTimeoutMinutes': 30
        }
    )

    device_farm_run_arn = schedule_run_response['run']['arn']

    run_start_time = schedule_run_response['run']['started']
    run_start_date_time = run_start_time.strftime("%m/%d/%Y, %H:%M:%S")
    print('run scheduled at ' + run_start_date_time)

    get_run_response = client.get_run(arn=device_farm_run_arn)
    while get_run_response['run']['result'] == 'PENDING':
        time.sleep(10)
        get_run_response = client.get_run(arn=device_farm_run_arn)

    run_end_time = datetime.datetime.now()
    run_end_date_time = run_end_time.strftime("%m/%d/%Y, %H:%M:%S")
    print('Run ended at ' + run_end_date_time + ' with result: ' + get_run_response['run']['result'])

    is_success = True
    if get_run_response['run']['result'] != 'PASSED':
        print('run has failed with result ' + get_run_response['run']['result'])
        is_success = False

    # If Clean up is not executed due to the job being cancelled in CI, the uploaded files will not be deleted
    # from the Device Farm project and must be deleted manually.

    # Clean up
    print('Deleting app file from Device Farm project')
    client.delete_upload(
        arn=device_farm_app_upload_arn
    )
    print('Deleting test package from Device Farm project')
    client.delete_upload(
        arn=device_farm_test_upload_arn
    )

    if is_success == False:
        print('Exiting with fail')
        sys.exit(-1)

    print('Exiting with success')

if __name__ == "__main__":
    main()
