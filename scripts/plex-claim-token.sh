#!/usr/bin/env bash

PLEX_CLIENT_IDENTIFIER=main

function missing_credentials() {
    echo "Please create the ~/.plex-crendentials file with 600 permissions." >&2
    echo "The first line of the file should be your Plex username, the second" >&2
    echo "line should be your Plex password." >&2
}

if [[ -f "$HOME/.plex-crendentials" ]]; then
    declare -a array
    while read -r; do
        array+=( "$REPLY" )
    done < "$HOME/.plex-crendentials"
    PLEX_USERNAME=${array[0]}
    PLEX_PASSWORD=${array[1]}
else
    echo "Error: Missing Plex credentials file (~/.plex-crendentials)." >&2
    echo
    missing_credentials
    exit 1
fi

if [[ -z "$PLEX_USERNAME" || -z "$PLEX_PASSWORD" ]]; then
    echo "Error: Cannot get your Plex username or password." >&2
    echo
    missing_credentials
    exit 1
fi

PLEX_AUTH=$(curl -sX "POST" "https://plex.tv/users/sign_in.json" \
    -H "X-Plex-Version: 1.0.0" \
    -H "X-Plex-Product: Plex Media Server" \
    -H "X-Plex-Client-Identifier: $PLEX_CLIENT_IDENTIFIER" \
    -H "Content-Type: application/x-www-form-urlencoded; charset=utf-8" \
    --data-urlencode "user[password]=$PLEX_PASSWORD" \
    --data-urlencode "user[login]=$PLEX_USERNAME" \
    |jq -r '.user.authToken')

PLEX_CLAIM=$(curl -sX "GET" "https://plex.tv/api/claim/token.json" \
    -H "X-Plex-Product: Plex SSO" \
    -H "X-Plex-Token: $PLEX_AUTH" \
    -H "X-Plex-Client-Identifier: $PLEX_USERNAME" \
    |jq -r '.token')

echo "$PLEX_CLAIM"

