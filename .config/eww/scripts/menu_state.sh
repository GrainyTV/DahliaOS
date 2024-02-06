#!/bin/sh

windowvar=$1
window=$( echo $windowvar | awk '{ gsub("_hidden", ""); gsub("_", ""); print }' )
state=$( eww get $windowvar )

if [[ $state == true ]]; then
    eww open $window
    eww update $windowvar=false
else
    eww close $window
    eww update $windowvar=true
fi