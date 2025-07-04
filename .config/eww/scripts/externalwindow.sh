#!/usr/bin/env bash

function main ()
{
    local windowName="$1"
    local isWindowOpen=$(eww active-windows | grep "^$windowName")

    if [[ $isWindowOpen ]]
    then
        eww update "${windowName}Hidden=true"
        eww close $windowName
    else
        eww update "${windowName}Hidden=false"
        eww open $windowName
    fi
}

main "$1"
