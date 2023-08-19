#!/bin/bash

# Read secrets from JSON file
SECRETS_FILE="./portfolio_secrets.json"
SECRETS_JSON=$(cat $SECRETS_FILE)

for key in $(echo "$SECRETS_JSON" | jq -r 'keys[]'); do
    SECRET_NAME=$key
    SECRET_VALUE=$(echo "$SECRETS_JSON" | jq -r ".$key")
    echo "$SECRET_NAME has value $SECRET_VALUE"
    export $SECRET_NAME="$SECRET_VALUE"
done