#!/bin/bash
###########
# Builds, archives, and exports all the apps in the 'configurations' folder.
# IPA and DSYM files will be placed in the 'products' folder.
#
# Requires Shenzhen: see https://github.com/nomad/shenzhen
###########

SCHEME=$1
CONFIGURATION=$2
PROVISIONING_PROFILE=$3
APP_NAME=$4

if [ "$SCHEME" == "" -o "$PROVISIONING_PROFILE" == "" -o "$CONFIGURATION" == "" ]; then
    echo "Usage: `basename $0` <scheme> <configuration> <provisioning profile UUID> [app name (optional)]"
    exit 1
fi

PROVISIONING_PROFILE_PATH="$HOME/Library/MobileDevice/Provisioning Profiles/$PROVISIONING_PROFILE.mobileprovision"
if [ ! -f "$PROVISIONING_PROFILE_PATH" ]; then
    echo "Provisioning profile $PROVISIONING_PROFILE_PATH not found."
    exit 1
fi

PROVISIONING_PROFILE_NAME=`/usr/libexec/PlistBuddy -c 'Print :Name' /dev/stdin <<< $(security cms -D -i "$PROVISIONING_PROFILE_PATH")`
if [ "$PROVISIONING_PROFILE_NAME" == "" ]; then
    echo "Provisioning profile $PROVISIONING_PROFILE_PATH could not be read."
    exit 1
fi

if [ "$APP_NAME" != "" -a ! -d "configurations/$APP_NAME" ]; then
    echo "App $APP_NAME not found."
    exit 1
fi


### Clean products folder

if [ -d "products" ]; then
    rm -rf products/*
else
    mkdir products
fi


### Go build!

cleanWorkingDir(){
    git reset --hard -q
    git clean -f -q
}

CONFIGS=`find configurations -type d -depth 1 -exec basename {} \;`
pushd victorious

for CONFIG in $CONFIGS
do
    if [ "$APP_NAME" != "" -a "$CONFIG" != "$APP_NAME" ]; then
        continue
    fi

    pushd ..
    cleanWorkingDir
    ./build-scripts/apply-config.sh $CONFIG
    popd

    ipa build -w victorious.xcworkspace -s "$SCHEME" -c "$CONFIGURATION" --clean --archive -d "../products" -m "$PROVISIONING_PROFILE_PATH" --verbose
    BUILDRESULT=$?

    if [ $BUILDRESULT ]; then
        mv ../products/victorious.ipa          "../products/$CONFIG.ipa"
        mv ../products/victorious.app.dSYM.zip "../products/$CONFIG.app.dSYM.zip"
    else
        cleanWorkingDir
        popd
        exit $BUILDRESULT
    fi

### xcodebuild equivalent of "ipa" command above, for posterity.
# xcodebuild -workspace victorious.xcworkspace -scheme $SCHEME -destination generic/platform=iOS -archivePath ../products/$CONFIG-int.xcarchive PROVISIONING_PROFILE="$PROVISIONING_PROFILE" archive
# xcodebuild -exportArchive -exportFormat ipa -archivePath ../products/$CONFIG-int.xcarchive -exportPath ../products/$CONFIG -exportProvisioningProfile "$PROVISIONING_PROFILE_NAME"

done

cleanWorkingDir
popd