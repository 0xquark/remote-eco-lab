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

for ((i = 1 ; i <= 2 ; i++)); do

    # burn in
    syncUp 1 #60

    # start
    timestamp "$i" "startTestrun"
    echo "start iteration $i"

    # start pause
    syncUp 1

    # open okular
    okular > /dev/null 2>&1 &

    # leave open for time (in seconds) for SUS
    # minus start pause minus wrap-up
    syncUp 208

    # wrap-up
    # quit okular
    echo " Quit Okular "
    timestamp "$i" "Quit Okular"
    xdotool key Ctrl+q
    syncUp 1

    echo " stop  iteration "
    timestamp "$i" "stopTestrun"

    # cool down
    syncUp 1

    # Remove logs
    rm ~/.config/katerc
    rm ~/.local/share/kate
    rm ~/.config/katemetainfos

    clear

done
