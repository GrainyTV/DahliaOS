#!/usr/bin/env bash

function main ()
{
    if [[ "$1" == "--active" ]]
    then
        local selectedWorkspaceId=1

        while true
        do
            local activeWorkspaceId=$(hyprctl activeworkspace -j | jaq .id)

            if [[ $activeWorkspaceId -ne $selectedWorkspaceId ]]
            then
                selectedWorkspaceId=$activeWorkspaceId
                echo "$selectedWorkspaceId"
            fi

            sleep 0.05
        done

    elif [[ "$1" == "--in-use" ]]; then
        local registeredWorkspacesInUse="[1]"

        while true
        do
            local workspacesInUse=$(hyprctl workspaces -j | jaq -c '[.[] | .id]')

            if [[ "$workspacesInUse" != "$registeredWorkspacesInUse" ]]
            then
                registeredWorkspacesInUse="$workspacesInUse"
                echo "$registeredWorkspacesInUse"
            fi

            sleep 0.05
        done
    fi
}

main "$1"
