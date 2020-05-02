#!/bin/bash

CREDENTIALS_FILE=${PROJECT_DIR}/iOS-UITests/Credentials.plist
DEFAULT_CREDENTIALS_FILE=${PROJECT_DIR}/iOS-UITests/Credentials-default.plist
BRAND_CREDENTIALS_FILE=${PROJECT_DIR}/iOS-UITests/Credentials-${BRAND_NAME}.plist

set -x

if [[ -f "$CREDENTIALS_FILE" ]]; then
    rm -f $CREDENTIALS_FILE
fi

if [[ -f "$DEFAULT_CREDENTIALS_FILE" ]]; then
    cp $DEFAULT_CREDENTIALS_FILE $CREDENTIALS_FILE
fi

if [[ -f "$BRAND_CREDENTIALS_FILE" ]]; then
    cp $BRAND_CREDENTIALS_FILE $CREDENTIALS_FILE
fi
