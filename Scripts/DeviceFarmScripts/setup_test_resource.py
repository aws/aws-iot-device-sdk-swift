# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0.

# The script will read a file with a list of KEY=SECRETES_ID. Then pull value of SECRETES_ID from Amazon secrets manager, and replace KEY with format "<KEY>" in the input file with pulled value. 
# For example. A file named id_secret.txt:
# ```
# REPLACE_KEY_1=SecretsManager_Secret_ID_1
# REPLACE_KEY_2=SecretsManager_Secret_ID_2
# ```
# And input_file::
# ```
#  var endpoint = "<REPLACE_KEY_1>"
#  var authorizer = "<REPLACE_KEY_2>"
# ```
# The script will pull secrets for SecretsManager_Secret_ID_1 and SecretsManager_Secret_ID_2, then update the input file with:
# ```
#  var endpoint = "pulled_value_for_SecretsManager_Secret_ID_1"
#  var var authorizer = "pulled_value_for_SecretsManager_Secret_ID_2"
# ```
# Usage:
#    Python setup_test_resource.py <key_secrets_file> <input_file> <region>
# 

import boto3
from botocore.exceptions import ClientError
import sys
import re

def get_secret(secret_name, region_name):
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        print(f"Error retrieving secret {secret_name}: {e}")
        return None

    if 'SecretString' in get_secret_value_response:
        return get_secret_value_response['SecretString']
    else:
        return None

def replace_in_file(file_path, replacements):
    try:
        with open(file_path, 'r') as file:
            content = file.read()
        
        for placeholder, replacement in replacements.items():
            content = content.replace(f"<{placeholder}>", replacement)
        
        with open(file_path, 'w') as file:
            file.write(content)
        
        print(f"Successfully updated {file_path}")
    except IOError as e:
        print(f"Error updating file: {e}")

def read_id_secrets(file_path):
    id_secrets = {}
    try:
        with open(file_path, 'r') as file:
            for line in file:
                match = re.match(r'(\w+)=(\S+)', line.strip())
                if match:
                    id_secrets[match.group(1)] = match.group(2)
    except IOError as e:
        print(f"Error reading ID-secrets file: {e}")
    return id_secrets

def main():
    if len(sys.argv) != 4:
        print("Usage: python setup_test_resource.py <key_secrets_file> <target_file> <region>")
        sys.exit(1)

    key_secrets_file = sys.argv[1]
    target_file = sys.argv[2]
    region_name = sys.argv[3]

    # Read ID-secrets pairs
    id_secrets = read_id_secrets(key_secrets_file)

    # Get secrets and prepare replacements
    replacements = {}
    for id, secret_name in id_secrets.items():
        secret_value = get_secret(secret_name, region_name)
        if secret_value is not None:
            replacements[id] = secret_value

    # Replace in file
    replace_in_file(target_file, replacements)

if __name__ == "__main__":
    main()
