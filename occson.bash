#!/usr/bin/env bash

ensure_command_exist() {
  if ! command -v $1 &> /dev/null
  then
    echo "${1} could not be found"
    exit
  fi
}

ensure_command_exist "curl"
ensure_command_exist "openssl"

access_token=""
passphrase=""
version="0.1.0"

commands_help="$(cat << EOF
Usage: occson [COMMAND [OPTIONS]]

Store, manage and deploy configuration securely with Occson.

Commands:
  cp                               Copy
  run                              Run command

Version: ${version}
EOF
)"

copy() {

copy_help="$(cat << EOF
Usage: occson cp [OPTIONS] <(LocalPath|STDIN)|(OccsonUri|Uri)> <(OccsonUri|Uri)|(LocalPath|STDOUT)>

Store, manage and deploy configuration securely with Occson.

Options:
    -a OCCSON_ACCESS_TOKEN,          Occson access token
        --access-token
    -p OCCSON_PASSPHRASE,            Occson passphrase
        --passphrase

Examples:
  Download to STDOUT
    occson cp occson://0.1.0/path/to/file.yml -
    occson cp https://api.occson.com/0.1.0/path/to/file.yml -
    occson cp http://host.tld:9292/0.1.0/path/to/file.yml -
    occson cp https://host.tld/0.1.0/path/to/file.yml -
  Download to local file
    occson cp occson://0.1.0/path/to/file.yml /local/path/to/file.yml
  Upload local file
    occson cp /local/path/to/file.yml occson://0.1.0/path/to/file.yml
  Upload content from STDIN
    echo "{ a: 1 }" | occson cp  - occson://0.1.0/path/to/file.yml
    cat /local/path/to/file.yml | occson cp - occson://0.1.0/path/to/file.yml

  Version: ${version}
EOF
)"

if [ "$#" -ne "6" ];
then
  echo -e "$copy_help"
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a)
      shift
      if [[ $# -gt 0 ]]; then
          access_token="$1"
      else
          (1>&2 echo "Require access_token")
          exit 22
      fi
    ;;

    --access-token=*)
      access_token="${1#--access-token=*}"
    ;;

    -p)
      shift
      if [[ $# -gt 0 ]]; then
          passphrase="$1"
      else
          (1>&2 echo "Require passphrase")
          exit 22
      fi
    ;;

    --passphrase=*)
      passphrase="${1#--passphrase=*}"
    ;;

    --help)
      echo -e "$copy_help"
      exit 0
    ;;

    *)
      break
    ;;
  esac
  shift
done

source=$1
destination=$2

if [[ $source =~ ^(occson|https?):// ]];
then
  uri="${source/occson:\/\//https://api.occson.com/}"
  json=$(curl -s -X GET $uri -H "Authorization: Bearer ${access_token}")
  encrypted_content=$(echo $json | grep -o 'encrypted_content":"[^"]*"' | sed 's/encrypted_content":"//' | sed 's/"//')

  decrypted_content="$(echo -n "$encrypted_content" | openssl enc -aes-256-cbc -md md5 -a -A -pass "pass:${passphrase}" -d)"

  if [[ $destination == "-" ]];
  then
    echo $decrypted_content
  else
    echo $decrypted_content >> $destination
  fi

else
  uri="${destination/occson:\/\//https://api.occson.com/}"

  if [[ $source == "-" ]];
  then
    content="$(</dev/stdin)"
  else
    content="$(cat $source)"
  fi

  encrypted_content="$(echo -n "$content" | openssl enc -aes-256-cbc -md md5 -a -A -pass "pass:${passphrase}")"

  body="{\"encrypted_content\":\"${encrypted_content}\"}"

  json=$(curl -s $uri -H "Authorization: Bearer ${access_token}" -H "Content-Type: application/json" -d "$body")
  echo $json
fi

}

run() {

run_help="$(cat << EOF
Usage: occson run [OPTIONS] <OccsonUri> -- <Command>

Store, manage and deploy configuration securely with Occson.

Options:
    -a OCCSON_ACCESS_TOKEN,          Occson access token
        --access-token
    -p OCCSON_PASSPHRASE,            Occson passphrase
        --passphrase

Examples:
  Run command with downloaded environment variables
    occson run occson://0.1.0/.env -- printenv

  Version: ${version}
EOF
)"

if [ "$#" -lt "7" ];
then
  echo -e "$run_help"
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a)
      shift
      if [[ $# -gt 0 ]]; then
          access_token="$1"
      else
          (1>&2 echo "Require access_token")
          exit 22
      fi
    ;;

    --access-token=*)
      access_token="${1#--access-token=*}"
    ;;

    -p)
      shift
      if [[ $# -gt 0 ]]; then
          passphrase="$1"
      else
          (1>&2 echo "Require passphrase")
          exit 22
      fi
    ;;

    --passphrase=*)
      passphrase="${1#--passphrase=*}"
    ;;

    --help)
      echo -e "$run_help"
      exit 0
    ;;

    *)
      break
    ;;
  esac
  shift
done

source=$1
shift 2
command=$@

uri="${source/occson:\/\//https://api.occson.com/}"
json=$(curl -s -X GET $uri -H "Authorization: Bearer ${access_token}")
encrypted_content=$(echo $json | grep -o 'encrypted_content":"[^"]*"' | sed 's/encrypted_content":"//' | sed 's/"//')
decrypted_content="$(echo -n "$encrypted_content" | openssl enc -aes-256-cbc -md md5 -a -A -pass "pass:${passphrase}" -d)"

export $(echo $decrypted_content | xargs)

$command

}

if [[ $1 == "cp" ]]; then
  shift
  copy $@
elif [[ $1 == "run" ]]; then
  shift
  run $@
else
  echo -e "${commands_help}"
  exit 22
fi
