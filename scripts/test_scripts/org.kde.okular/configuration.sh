#! /usr/bin/env bash

okular > /dev/null 2>&1 &

## Setting custom shortcuts
echo "Importing Shortcuts"
sleep 2
xdotool key Ctrl+Alt+comma
sleep 2
for ((i = 0; i < 2; i++))
do
    xdotool key Tab
done
xdotool key Return
sleep 2
for ((i = 0; i < 8; i++))
do
    xdotool key Tab
done
xdotool key Return
for ((i = 0; i < 3; i++))
do
    xdotool key Tab
done
xdotool key Return

xdotool key Ctrl+f
sleep 1
xdotool type "test_data/keyboard_shortcuts.shortcuts"
sleep 5
xdotool key Return
sleep 2
xdotool key Escape

echo "Finished importing shortcuts"

echo "Quitting Okular"
xdotool key Ctrl+q
