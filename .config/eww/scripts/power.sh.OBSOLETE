#!/bin/sh

declare -A commands=(
	["poweroff"]="loginctl poweroff"
	["sleep"]="loginctl suspend"
	["restart"]="loginctl reboot"
) 
execute=$1

${commands[$execute]}