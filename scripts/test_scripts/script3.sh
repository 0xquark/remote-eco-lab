#!/usr/bin/env bash

startTime=$(date +%s%N)
elapsed=0

syncUp() {
    elapsed=$((elapsed + ($1 * 1000000000)))
    delta=$(echo "scale=10; (($startTime + $elapsed) - $(date +%s%N)) / 1000000000" | bc)
    echo "Sleep" $delta
    sleep $delta
}

timestamp() {
    echo "iteration $1;$(date -I) $(date +%T);$2 " >> ~/log_idle.csv
}

for ((i = 1 ; i <= 1 ; i++)); do

    # burn in
    syncUp 10 #60

    # start
    timestamp "$i" "startTestrun"
    echo "start iteration $i"

    # start pause
    syncUp 5

    # open kate
    kate > /dev/null 2>&1 & # open kate

    # leave open for time (in seconds)
    # for SUS minus start pause minus wrap-up
    syncUp 20

    # wrap-up
    # quit kate
    xdotool key Ctrl+1            #custom
    syncUp 2
    xdotool key ISO_Left_Tab
    syncUp 2
    xdotool key Return
    syncUp 5

    echo " stop  iteration "
    timestamp "$i" "stopTestrun"

    # cool down
    syncUp 5

    # Remove logs
    rm ~/.config/katerc
    rm ~/.local/share/kate
    rm ~/.config/katemetainfos

    clear

done
