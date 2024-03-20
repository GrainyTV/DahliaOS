#!/bin/sh

apiKey=$( echo "$GYAZO_API_KEY" )

if [[ $# -eq 0 || -z "$apiKey" ]]; then
    exit

fi

selectedArea=$1
id=$( tr -dc A-Za-z0-9 </dev/urandom | head -c 10; echo )
tmpFile="/tmp/image_upload_${id}.png"

grim -g "$selectedArea" "$tmpFile"

if [[ ! -f "$tmpFile" ]]; then
    exit

fi

result=$( curl -is "https://upload.gyazo.com/api/upload" \
    -F "access_token=${apiKey}" \
    -F "imagedata=@${tmpFile}"
)
header=$( echo "$result" | awk 'BEGIN { RS="\r\n\r\n" } NR==1' )

if [[ ! $header == *"HTTP/2 200"* ]]; then
    rm "$tmpFile"
    exit

fi

body=$( echo "$result" | awk 'BEGIN { RS="\r\n\r\n" } NR==2' )
url=$( echo "$body" | jq -r '.permalink_url' )

xdg-open "$url" &
rm "$tmpFile"