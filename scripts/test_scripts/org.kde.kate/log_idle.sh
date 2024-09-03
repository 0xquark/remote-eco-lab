#!/usr/bin/env bash

startTime=$(date +%s%N)
elapsed=0

# syncUp function is used to get accurate time to be elapsed
syncUp() {
    elapsed=$((elapsed + ($1 * 1000000000)))
    delta=$(echo "scale=10; (($startTime + $elapsed) - $(date +%s%N)) / 1000000000" | bc)
    echo "Sleep" $delta
    sleep $delta
}

# timestamp function is used to output the time and action into log.csv file
timestamp() {
    echo "iteration $1;$(date -I) $(date +%T);startAction;$2 " >> ~/log_idle.csv
}

# Loop running for 30 times
# start loop
for ((i = 1 ; i <= 3 ; i++)); do

    # burn in
    syncUp 10 #60

    # start
    echo "iteration $i;$(date -I) $(date +%T);startTestrun" >> ~/log_idle.csv
    echo "start iteration $i"

    # start pause
    syncUp 1

    # open kate
    echo " open kate "
    timestamp "$i" "open kate"
    kate > /dev/null 2>&1 & # open kate
    syncUp 1

    # leave open for time (in seconds)
    # for SUS minus start pause minus wrap-up
    syncUp 3

    # wrap-up
    # quit kate
    echo " quit kate "
    timestamp "$i" "quit kate"
    xdotool key Ctrl+1            #custom
    syncUp 1
    xdotool key ISO_Left_Tab
    syncUp 1
    xdotool key Return
    syncUp 1

    # stop iteration
    echo " stop iteration "
    echo "iteration $i;$(date -I) $(date +%T);stopTestrun" >> ~/log_idle.csv

    # cool down
    syncUp 10 #60

    # Remove logs
    rm ~/.config/katerc
    rm ~/.local/share/kate
    rm ~/.config/katemetainfos

    clear

done
