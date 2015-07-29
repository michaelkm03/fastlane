#!/bin/bash
###########
# Generates the appropriate app ID for the build scheme and app configuration.
###########

FOLDER=$1
SCHEME=$2

if [ "$FOLDER" == "" ]; then
    exit 0
fi

# Default App ID key: the plist key that contains the app ID that corresponds to the configuration we're building.
if [ "$SCHEME" == "Release" -o "$SCHEME" == "Stable" ]; then
    DEFAULT_APP_ID_KEY="VictoriousAppID"
elif [ "$SCHEME" == "Staging" ]; then
    DEFAULT_APP_ID_KEY="StagingAppID"
elif [ "$SCHEME" == "QA" ]; then
    DEFAULT_APP_ID_KEY="QAAppID"
else
    DEFAULT_APP_ID_KEY="VictoriousAppID"
fi

DEFAULT_APP_ID=$(/usr/libexec/PlistBuddy -c "Print $DEFAULT_APP_ID_KEY" "$FOLDER/Info.plist" 2> /dev/null)

echo $DEFAULT_APP_ID
