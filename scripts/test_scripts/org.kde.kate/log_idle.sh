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

# startAction / stopAction functions are used to output the time and action into log.csv file
startAction() {
    echo "iteration $1;$(date -I) $(date +%T);startAction;$2 " >> ~/log_idle.csv
}
stopAction() {
    echo "iteration $1;$(date -I) $(date +%T);stopAction " >> ~/log_idle.csv
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
    startAction "$i" "open kate"
    kate > /dev/null 2>&1 & # open kate
    syncUp 1
    stopAction "$i"

    # leave open for time (in seconds)
    # for SUS minus start pause minus wrap-up
    echo " idle "
    startAction "$i" "idle"
    syncUp 3
    stopAction "$i"

    # wrap-up
    # quit kate
    echo " quit kate "
    startAction "$i" "quit kate"
    xdotool key Ctrl+1            #custom
    syncUp 1
    xdotool key ISO_Left_Tab
    syncUp 1
    xdotool key Return
    syncUp 1
    stopAction "$i"

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
