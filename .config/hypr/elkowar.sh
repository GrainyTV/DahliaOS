#!/bin/bash

function isEwwActive ()
{
    eww ping | grep "pong"
    return $?
}

eww open statusbar

while [[ ! $(isEwwActive) ]]
do
    sleep 1
done

$(eww get EWW_CONFIG_DIR)/scripts/appsearch.sh --populate
