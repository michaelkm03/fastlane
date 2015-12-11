# VictoriousiOS
Victorious iOS app

## Deployment

### Prerequisites
- Install [Homebrew](http://brew.sh)
- Install the version of Xcode which was used to develop the latest app version on the master branch
- Install rbenv using [these instructions](http://www.startprogrammingnowbook.com/book/setup#uid10)

### Setup

#### Installation

```
brew install python
pip install requests
xcode-select --switch <path_to_xcode_developer_folder>
xcode-select --install # install command line tools
cd <project_dir>/victorious/fastlane
rbenv install
gem install bundler
bundle install
```

#### Environment variables

Add the following environment variables to the `victorious/fastlane/.env` file

```
FASTLANE_USER=<VAMS iTunesConnect account email>
FASTLANE_PASSWORD=<VAMS iTunesConnect account password>
PRODUCTION_VAMS_USER='<production_username>'
PRODUCTION_VAMS_PASSWORD='<production_password>'
STAGING_VAMS_USER='<staging_username>'
STAGING_VAMS_PASSWORD='<staging_password>'
DEV_VAMS_USER='<development_username>'
DEV_VAMS_PASSWORD='<development_password>'
LOCAL_VAMS_USER='<local_username>'
LOCAL_VAMS_PASSWORD='<local_password>'
```

### Build and Push

```
cd <project_dir>/victorious/fastlane
gem install fastlane
fastlane ios deploy
```

Fastlane runs in production environment by default. If you want to run it in a different environment, just specify `environment:<your_environment_here>` at the end of the fastlane command. See the example below:

```
fastlane ios deploy                 # deploys to production
fastlane ios deploy environment:dev # deploys to dev
```
