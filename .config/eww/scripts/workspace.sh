#!/usr/bin/env bash

function main ()
{   
    case "$1" in
        "--active")
            local selectedWorkspace=1

            while true
            do
                local activeWorkspace=$(hyprctl activeworkspace -j | jaq '.id')

                if [[ $activeWorkspace -ne $selectedWorkspace ]]
                then
                    selectedWorkspace=$activeWorkspace
                    echo "$selectedWorkspace"
                fi

                sleep 0.05
            done ;;

        "--in-use")
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
            done ;;

        "--switch-left")
            local activeWorkspace=$(eww get active_workspace)
            local workspacesInUse=$(eww get workspaces_in_use)
            local chosenWorkspaceOrNull=$(echo "$workspacesInUse" | jaq "map(select(. < $activeWorkspace)) | max")

            if [[ "$chosenWorkspaceOrNull" != "null" ]]
            then
                hyprctl dispatch workspace "$chosenWorkspaceOrNull"
            fi ;;

        "--switch-right")
            local activeWorkspace=$(eww get active_workspace)
            local workspacesInUse=$(eww get workspaces_in_use)
            local chosenWorkspaceOrNull=$(echo "$workspacesInUse" | jaq "map(select(. > $activeWorkspace)) | min")

            if [[ "$chosenWorkspaceOrNull" != "null" ]]
            then
                hyprctl dispatch workspace "$chosenWorkspaceOrNull"
            fi ;;
    esac
}

main "$1"
