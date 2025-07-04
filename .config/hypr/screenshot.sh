#!/bin/sh

OUTPUT="$( xdg-user-dir PICTURES )/$( date +'%Y-%m-%dT%H:%M:%S' ).png"

if [ "$1" = "--fs" ]; then
    grim $OUTPUT

else
    grim -g "$( slurp -w0 )" $OUTPUT

fi

xdg-open $OUTPUT > /dev/null 2>&1 &

sleep 1

IMAGE_VIEWER="$( xdg-mime query default image/png )"
WM_CLASS="$( cat /usr/share/applications/$IMAGE_VIEWER | grep WM | awk -F= '{ print $2 }' )"
FOCUS_IDENTIFIER=$( hyprctl clients | grep -m1 $WM_CLASS | awk '{ print $2 }' )
hyprctl dispatch focuswindow initialclass:$FOCUS_IDENTIFIER
