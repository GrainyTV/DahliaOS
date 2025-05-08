#!/usr/bin/env bash

function tryGetIniPropertyByKey ()
{
    local key=$1
    local text=$2

    echo "$text" | grep -Po "(?<=^$key=).*"
}

function tryGetIniProperties ()
{
    local config=$1
    local executable=$2
    
    if [[ $(echo "$config" | grep "NoDisplay=true") ]]
    then
        return 1
    fi

    local nameProperty="Name"
    local iconProperty="Icon"
    local descriptionProperties=("Comment" "GenericName")

    local name=$(tryGetIniPropertyByKey "$nameProperty" "$config")
    local icon=$(tryGetIniPropertyByKey "$iconProperty" "$config")
    local description=$(tryGetIniPropertyByKey "${descriptionProperties[0]}" "$config")

    if [[ -z "$description" ]]
    then
        description=$(tryGetIniPropertyByKey "${descriptionProperties[1]}" "$config")

        if [[ -z "$description" ]]
        then
            description="....."
        fi
    fi

    jaq -nc \
       --argjson name "\"$name\"" \
       --argjson desc "\"$description\"" \
       --argjson icon "\"$icon\"" \
       --argjson exec "\"$executable\"" \
       '{name:$name,desc:$desc,icon:$icon,exec:$exec}'
}

function processDesktopEntry ()
{
    local entry="$1"
    local executable=$(basename "$entry" ".desktop")
    local desktopEntrySection=$(grep -Poz "(?<=\[Desktop Entry\]\n)(.|\n)*?(?=(\n\[)|\z)" "$entry" | tr -d '\0')

    local iniJson
    iniJson=$(tryGetIniProperties "$desktopEntrySection" "$executable") || return 1

    echo "$iniJson"
}

function desktopEntriesAsJson ()
{
    local appsFolder="/usr/share/applications"
    
    export -f tryGetIniProperties
    export -f tryGetIniPropertyByKey
    export -f processDesktopEntry

    find "$appsFolder" -name "*.desktop" -print0 \
    | parallel -0 -j $(nproc) processDesktopEntry {} \
    | jaq -sc '. | sort_by(.name|ascii_downcase)'
}

function tryGetCachedHash ()
{
    local cacheDir=$1
    local cacheFile=$2

    if [[ ! -d "$cacheDir" ]]
    then
        mkdir -p "$cacheDir"
        return 1
    fi

    if [[ ! -f "$cacheFile" ]]
    then
        return 1
    fi

    cat "$cacheFile"
}

function main ()
{
    local ewwDir
    ewwDir=$(eww get "EWW_CONFIG_DIR")

    if [[ $? -eq 1 ]]
    then
        echo "Eww daemon is not running. It is a dependency of appsearch.sh script." 1>&2
        return 1
    fi

    local cacheDir="$ewwDir/.cache"
    local cacheFile="$cacheDir/eww_apps.hash"
    local jsonFile="$cacheDir/eww_apps.json"

    if [[ "$1" == "--populate" ]]
    then
        local currentJsonArray=$(desktopEntriesAsJson)
        local cachedHash=$(tryGetCachedHash "$cacheDir" "$cacheFile")
        local computedHash=$(echo "$currentJsonArray" | md5sum | awk '{ print $1 }')

        if [[ "$cachedHash" == "$computedHash" ]]
        then
            eww update applications="$(cat "$jsonFile")"
        else
            echo "$currentJsonArray" > "$jsonFile"
            echo "$computedHash" > "$cacheFile" 
            eww update applications="$currentJsonArray"
        fi

    elif [[ "$1" == "--monitor" ]]
    then
        while true
        do
            local currentJsonArray=$(desktopEntriesAsJson)
            local cachedHash=$(tryGetCachedHash "$cacheDir" "$cacheFile")
            local computedHash=$(echo "$currentJsonArray" | md5sum | awk '{ print $1 }')

            if [[ "$cachedHash" != "$computedHash" ]]
            then
                echo "$currentJsonArray"
                echo "$currentJsonArray" > "$jsonFile"
                echo "$computedHash" > "$cacheFile"
            fi

            sleep 5
        done
    fi
}

main "$1"
