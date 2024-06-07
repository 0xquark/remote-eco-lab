#!/usr/bin/env bash

# Make sure LibreOffice is not running
pgrep soffice | xargs kill -9

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

# Loop running for 30 times
for ((i = 1 ; i <= 2; i++)); do

    # burn in
    syncUp 10 #60

    # start
    timestamp "$i" "startTestrun"
    echo "start iteration $i"

    # start pause
    syncUp 5

    # open writer
    flatpak run org.libreoffice.LibreOffice --writer 2>&1 &

    # leave open for time (in seconds)
    # for SUS minus start pause minus wrap-up
    syncUp 20

    # Close the tip of the day dialog
    xdotool key Return
    syncUp 2

    # wrap-up
    # quit writer
    xdotool key Ctrl+w
    syncUp 5

    # quit LibreOffice
    xdotool key Ctrl+w
    syncUp 5

    echo " stop  iteration "
    timestamp "$i" "stopTestrun"

    # cool down
    syncUp 5

    # Remove user directory
    rm -rf ~/.var/app/org.libreoffice.LibreOffice/

done
