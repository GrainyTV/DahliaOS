#!/usr/bin/env bash

function hyprctl ()
{
    local command="$1"
    local infoSocket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket.sock"

    echo -n "[j]/$command" | socat - UNIX-CONNECT:"$infoSocket"
}

function getIconName ()
{
    local inputFile="$1"
    grep -Po "(?<=^Icon=).*" "$inputFile"
}

function tryGetDesktopEntryWithMatchingExecField ()
{
    local exec="$1"
    local appsDir="/usr/share/applications"
    
    local desktopEntries
    desktopEntries=$(grep -Pr "(?<=Exec=).*$exec" "$appsDir")

    if [[ $? -ne 0 ]]
    then
        return 1
    fi

    echo "$desktopEntries" | head -n1 | awk -F ':' '{ print $1 }'
}

function trackDownApplicationIcon ()
{
    local json="$1"
    local pid=$(echo "$json" | jaq '.pid')

    local execField=$(cat "/proc/$pid/comm")

    local desktopEntry
    desktopEntry=$(tryGetDesktopEntryWithMatchingExecField "$execField")

    if [[ $? -eq 0 ]]
    then
        local icon=$(getIconName "$desktopEntry")
        jaq -n \
            --argjson visible "$(echo "$json" | jaq '.visible')" \
            --argjson icon "\"$icon\"" \
            --argjson address "$(echo "$json" | jaq '.address')" \
            '{visible:$visible,icon:$icon,address:$address}'
    fi
}

function checkForStatusbarChanges ()
{
    local event="$1"
    local workspace="$2"

    case "$event" in
        "workspacev2" | "openwindow" | "closewindow" | "movewindowv2")
            local statusbarApps=$(hyprctl "clients" \
                | jaq -c ".[]
                    | select(
                        .workspace.id == $workspace
                        or (.workspace.name == \"special:Hidden\" and any(.tags[]; . == \"$workspace\"))
                        )
                    | . + { visible: (.workspace.id == $workspace) }
                    | { address, initialClass, pid, visible }" \
                | parallel -j $(nproc) trackDownApplicationIcon {} \
                | jaq -sc '. | sort_by(.address)')

            echo "$statusbarApps"
            ;;
    esac
}

function main ()
{
    if [[ -z "$XDG_RUNTIME_DIR" || -z "$HYPRLAND_INSTANCE_SIGNATURE" ]]
    then
        echo "Either XDG_RUNTIME_DIR or HYPRLAND_INSTANCE_SIGNATURE is not set." 1>&2
        return 1
    fi

    export -f getIconName
    export -f tryGetDesktopEntryWithMatchingExecField
    export -f trackDownApplicationIcon

    local eventSocket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
    local selectedWorkspace=$(hyprctl "activeworkspace" | jaq '.id')

    socat -U - UNIX-CONNECT:"$eventSocket" | while read -r line
    do
        local event=$(echo "$line" | awk -F '>>' '{ print $1 }')

        if [[ "$event" == "workspacev2" ]]
        then
            local id=$(echo "$line" | awk -F '>>' '{ print $2 }' | awk -F ',' '{ print $1 }')

            if [[ "$selectedWorkspace" -ne "$id" ]]
            then
                selectedWorkspace="$id"
            fi
        fi

        checkForStatusbarChanges "$event" "$selectedWorkspace"
    done
}

main
