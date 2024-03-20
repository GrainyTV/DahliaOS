#!/bin/sh

toLower () {
    parameter="$1"
    result=$( echo "$parameter" | awk '{ print tolower($0) }' )
    echo "$result"
}

loadProperty () {
    property="^$1="
    content="$2"
    result=$( echo "$content" | grep "$property" | head -n1 | awk -F= '{ print $2 }' )
    echo "$result"
}

loadImage () {
    icon="$1"
    HOME=$( echo $HOME )
    paths=("$icon" \
           "${HOME}/.local/share/icons/Tela-circle-orange/scalable/apps/${icon}.svg" \
           "/usr/share/icons/hicolor/scalable/apps/${icon}.svg" \
           "/usr/share/icons/hicolor/256x256/apps/${icon}.png")

    for path in "${paths[@]}"; do
        if [[ -f "$path" ]]; then
            echo "$path"
            return
    
        fi

    done

    echo ""
}

matchesNameFilter () {
    name="$1"
    filter="$2"
    
    if [[ $name == *"$filter"* ]]; then
        return 0
    
    else
        return 1

    fi
}

hasIcon () {
    content="$1"
    icon=$( echo "$content" | grep "^Icon=" )
    
    if [[ -z "$icon" ]]; then
        return 1

    else
        return 0

    fi
}

#-----------------------#
# ENTRY POINT OF SCRIPT #
#-----------------------#

for pid in $( pidof -x "$0" ); do
    if [[ $pid != $$ ]]; then
        kill $pid
    
    fi 

done

array=()
filter=$( toLower "$*" )
files=$( find /usr/share/applications/ -maxdepth 1 -type f -name "*.desktop" )

for fileName in $files; do
    content=$( cat "$fileName" )
    lowerCaseName=$( toLower "$( loadProperty "Name" "$content" )" )

    if matchesNameFilter "$lowerCaseName" "$filter" && hasIcon "$content"; then 
        icon=$( loadImage "$( loadProperty "Icon" "$content" )" )

        if [[ -n "$icon" ]]; then
            name=$( loadProperty "Name" "$content" )
            genericName=$( loadProperty "GenericName" "$content" )
            comment=$( loadProperty "Comment" "$content" )
            desc=${genericName:-${comment:-"N.A."}}
            exec=$( basename "$fileName" ) 

            jsonObject=$( jq -n \
                --arg title "$name" \
                --arg description "$desc" \
                --arg icon "$icon" \
                --arg exec "$exec" \
                '$ARGS.named' )
            array+=("$jsonObject")

        fi

    fi

done

jsonArrayResult=$( jq -n '$ARGS.positional | sort_by(.title | ascii_downcase)' --jsonargs "${array[@]}" )
eww update search_content="$jsonArrayResult"