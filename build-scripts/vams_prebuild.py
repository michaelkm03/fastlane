#!/usr/bin/python

# Author: Lawrence H. Leach - Sr. Software Engineer
# Note: Hash calculating code was "borrowed" from Frank Zhao.
# Date: 07/01/2015
# Copyright 2015 Victorious Inc. All Rights Reserved.

"""
Authenticates with the Victorious backend, retrieves the latest app configuration data,
app assets and writes them to a temporary directory.

"""
import requests
import sys
import os
import hashlib
import subprocess
import urllib


_LOGIN_ENDPOINT = '/api/login'
_ASSETS_ENDPOINT = '/api/app/appassets_by_build_name'
_TEMPLATE_ENDPOINT = '/api/app/template'

_DEFAULT_VAMS_USERID = 0
_DEFAULT_VAMS_USER = 'vicky@example.com'
_DEFAULT_VAMS_PASSWORD = 'abc123456'

_DEFAULT_USERAGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.130 Safari/537.36 aid:1 uuid:FFFFFFFF-0000-0000-0000-FFFFFFFFFFFF build:1'
_DEFAULT_HEADERS = ''
_DEFAULT_HEADER_DATE = ''

_DEFAULT_PLATFORM = 'android'
_DEFAULT_HOST = ''
_PRODUCTION_HOST = 'http://api.getvictorious.com'
_STAGING_HOST = 'http://staging.getvictorious.com'
_QA_HOST = 'http://qa.getvictorious.com'
_DEV_HOST = 'http://dev.getvictorious.com'

_AUTH_TOKEN = ''
_CONFIG_DIRECTORY = 'app/configuration/'


def authenticateUser():
    """
    Authenticates a user against the Victorious backend API.

    :return:
        A JSON object of details returned by the Victorious backend API.
    """
    url = '%s%s' % (_DEFAULT_HOST, _LOGIN_ENDPOINT)

    global _DEFAULT_HEADER_DATE
    _DEFAULT_HEADER_DATE = subprocess.check_output("date", shell=True).rstrip()
    postData = {'email':_DEFAULT_VAMS_USER,'password':_DEFAULT_VAMS_PASSWORD}
    headers = {'User-Agent':_DEFAULT_USERAGENT,'Date':_DEFAULT_HEADER_DATE}
    r = requests.post(url, data=postData, headers=headers)

    if not r.status_code == 200:
        return False

    response = r.json()

    # Return the authentication JSON object
    setAuthenticationToken(response)

    return True


def setAuthenticationToken(json_object):
    """
    Checks to see if there is a user token in the JSON response object
    of a login call. If there is, the script stores it in the global
    variable

    :param json_object:
        The response object from a authentication call. (May be blank.)

    :return:
        Nothing - If token object exists in JSON payload, then it is saved
        to a global variable.
    """
    global _AUTH_TOKEN
    global _DEFAULT_VAMS_USERID

    payload = json_object['payload']
    if 'token' in payload:
        _AUTH_TOKEN = payload['token']

    if 'user_id' in json_object:
        _DEFAULT_VAMS_USERID = json_object['user_id']


def calcAuthHash(endpoint, reqMethod):
    """
    Calculates the Victorious backend authentication hash

    :param endpoint:
        The API endpoint being called

    :param reqMethod:
        The request method type 'GET' or 'POST'

    :return:
        A SHA1 hash used to authenticate subsequent requests
    """
    return hashlib.sha1(_DEFAULT_HEADER_DATE + endpoint + _DEFAULT_USERAGENT + _AUTH_TOKEN + reqMethod).hexdigest()


def retrieveAppDetails(app_name):
    """
    Collects all of the design assets for a given app

    :param app_name:
        The app name of the app whose assets to be downloaded.

    :return:
        0 - For success
        1 - For error
    """

    # Calculate request hash
    uri = '%s/%s' % (_ASSETS_ENDPOINT, app_name)
    url = '%s%s' % (_DEFAULT_HOST, uri)
    req_hash = calcAuthHash(uri, 'GET')

    auth_header = 'BASIC %s:%s' % (_DEFAULT_VAMS_USERID, req_hash)
    headers = {
        'Authorization':auth_header,
        'User-Agent':_DEFAULT_USERAGENT,
        'Date':_DEFAULT_HEADER_DATE
    }
    response = requests.get(url, headers=headers)

    json = response.json()
    payload = json['payload']
    app_title = payload['app_title']
    app_title = app_title.replace(' ','')
    assets = payload['assets']
    platform_assets = assets[_DEFAULT_PLATFORM]

    current_cnt = 0

    global _CONFIG_DIRECTORY

    if _DEFAULT_PLATFORM == 'ios':
        _CONFIG_DIRECTORY = 'configurations/'

    config_directory = '%s%s' % (_CONFIG_DIRECTORY, app_title)
    if not os.path.exists(config_directory):
        os.makedirs(config_directory)

    print '\nDownloading the Most Recent Art Assets for %s...' % app_title
    for asset in platform_assets:

        if not platform_assets[asset] == None:
            img_url = platform_assets[asset]
            asset_name = asset.replace('_', '-')
            new_file = '%s/%s.png' % (config_directory, asset_name)

            print '%s (%s)' % (asset_name, platform_assets[asset])

            urllib.urlretrieve(img_url,new_file)
            current_cnt = current_cnt+1

    print '\n%s images downloaded' % current_cnt
    print ''

    # Now set the app config data
    setAppConfig(json)


def setAppConfig(json_obj):
    """
    Parses a JSON object for app configuration data and writes it out to
    an app configuration file

    :param json_obj:
        The JSON object to parse that contains the app configuration data
    """
    payload = json_obj['payload']
    app_config = payload['configuration'][_DEFAULT_PLATFORM]
    app_title = payload['app_title']
    app_title = app_title.replace(' ','')

    config_directory = '%s%s' % (_CONFIG_DIRECTORY, app_title)
    file_name = 'config.xml'
    if _DEFAULT_PLATFORM == 'ios':
        file_name = 'Info.plist'
    config_file = '%s/%s' % (config_directory, file_name)

    print 'Applying Most Recent App Configuration Data to %s' % app_title
    print ''
    print app_config

    # Write config file to disk
    f = open(config_file, 'w')
    f.write(app_config)
    f.close()


def main(argv):
    if len(argv) < 3:
        print ''
        print 'Usage: ./vams_prebuild.py <app_name> <platform> <environment>'
        print ''
        print '<app_name> is the name of the application data to retrieve from VAMS.'
        print '<platform> is the OS platform for which the assets need to be downloaded for.'
        print '<environment> is the server environment to retrieve the application data from.'
        print 'If no <environment> parameter is provided, the system will use PRODUCTION.'
        print ''
        print 'examples:'
        print './pre_build.py 24     <-- will use PRODUCTION'
        print '  -- OR --'
        print './pre_build.py 24 qa  <-- will use QA'
        print ''
        return 1

    global _DEFAULT_HOST
    global _DEFAULT_PLATFORM

    app_name = argv[1]
    platform = argv[2]
    if platform == 'ios':
        _DEFAULT_PLATFORM = 'ios'


    if len(argv) == 4:
        server = argv[3]
    else:
        server = ''

    if server.lower() == 'dev':
        _DEFAULT_HOST = _DEV_HOST
    elif server.lower() == 'qa':
        _DEFAULT_HOST = _QA_HOST
    elif server.lower() == 'staging':
        _DEFAULT_HOST = _STAGING_HOST
    elif server.lower() == 'production':
        _DEFAULT_HOST = _PRODUCTION_HOST
    else:
        _DEFAULT_HOST = _PRODUCTION_HOST
        
    print ''
    print 'Using host: %s' % _DEFAULT_HOST
    print ''

    # Authenticate
    if authenticateUser():
        retrieveAppDetails(app_name)
    else:
         print 'There was a problem authenticating with the Victorious backend. Exiting now...'
         return 1

    print 'Configuration and assets applied successfully!'
    print ''
    
    return 0


if __name__ == '__main__':
    main(sys.argv)
