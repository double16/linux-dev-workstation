#!/bin/bash -e

ORG="$1"
NAME="$2"
PROVIDER="$3"
VERSION="$4"
FILE="$5"

if [ -z "$ORG" -o -z "$NAME" -o -z "$PROVIDER" -o -z "$VERSION" -o -z "$FILE" ]; then
  tput setaf 1; printf "Usage: $0 [org] [name] [provider] [version] [file]\n\n"; tput sgr0
  exit 1
fi

CURL=curl

# Cross platform scripting directory
pushd `dirname $0` > /dev/null
BASE=`pwd -P`
popd > /dev/null

# The jq tool is needed to parse JSON responses
if ! command -v jq ; then
  tput setaf 1; printf "\n\nThe 'jq' utility is not installed.\n\n\n"; tput sgr0
  exit 1
fi

# Ensure the credentials file is available
if [ -f $BASE/.credentialsrc ]; then
  source $BASE/.credentialsrc
else
  tput setaf 1; printf "\nError. The $BASE/.credentialsrc file is missing.\n\n"; tput sgr0
  exit 2
fi

if [ -z ${VAGRANT_CLOUD_TOKEN} ]; then
  tput setaf 1; printf "\nError. VAGRANT_CLOUD_TOKEN is missing. Add it to the $BASE/.credentialsrc file.\n\n"; tput sgr0
  exit 2
fi

printf "\n\n"

# Create the version
${CURL} \
  --tlsv1.2 \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  "https://app.vagrantup.com/api/v1/box/$ORG/$NAME/versions" \
  --data "
    {
      \"version\": {
        \"version\": \"$VERSION\",
        \"description\": \"A build environment for use in cross platform development.\"
      }
    }
  "
printf "\n\n"

# Create the provider
${CURL} \
  --tlsv1.2 \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/box/$ORG/$NAME/version/$VERSION/providers \
  --data "{ \"provider\": { \"name\": \"$PROVIDER\" } }"

printf "\n\n"

# Prepare an upload path, and then extract that upload path from the JSON
# response using the jq command.
UPLOAD_PATH=`${CURL} \
  --fail \
  --tlsv1.2 \
  --silent \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/box/$ORG/$NAME/version/$VERSION/provider/$PROVIDER/upload | jq -r .upload_path`

# Perform the upload
${CURL} --fail --tlsv1.2 --include --max-time 7200 --expect100-timeout 7200 --request PUT --output "$FILE.upload.log.txt" --upload-file "$FILE" "$UPLOAD_PATH"

printf "\n-----------------------------------------------------\n"
tput setaf 5
cat "$FILE.upload.log.txt"
tput sgr0
printf -- "-----------------------------------------------------\n\n"

# Release the version
${CURL} \
  --fail \
  --tlsv1.2 \
  --silent \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/box/$ORG/$NAME/version/$VERSION/release \
  --request PUT | jq '.status,.version,.providers[]' | grep -vE "hosted|hosted_token|original_url|created_at|updated_at|\}|\{"

printf "\n\n"
