#!/usr/bin/env bash

function main ()
{
    devices=$(
        nmcli --terse -f 'DEVICE,TYPE,STATE,CONNECTION' device \
        | jaq -Rsc 'split("\n")
                    | map(select(. != ""))
                    | map(split(":"))
                    | map({"device": .[0], "type": .[1], "state": .[2], "connection": .[3]})'
    )

    isConnected=$(
        jaq 'map(select(.type == "ethernet" or .type == "wireless"))
             | map(select(.state == "connected"))
             | length > 0' <<< "$devices"
    )

    echo "$isConnected"
}

main
