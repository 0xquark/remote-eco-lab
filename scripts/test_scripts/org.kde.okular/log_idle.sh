#! /usr/bin/env bash

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

# Start scripts with everything fresh
# Make sure Okular is not running
killall okular
# Remove previous logs and dot-files
rm -f ~/log_idle.csv
rm -f ~/.config/okularrc
rm -f ~/.config/okularpartrc
rm -f -r ~/.local/share/okular/*

for ((i = 0; i <= 10; i++)); do

    # burn in
    syncUp 30

    # start
    echo "iteration $i;$(date -I) $(date +%T);startTestRun" >> ~/log_idle.csv
    echo "start iteration $i"

    # start pause
    syncUp 5

    # open okular
    okular > /dev/null 2>&1 & # open okular

    # leave open for time (in seconds)
    # for SUS minus start pause minus wrap-up
    syncUp 203

    # wrap-up
    # quit okular
    echo " Quit Okular "
    timestamp "$i" "Quit Okular"
    xdotool key Ctrl+q
    syncUp 2

    echo " stop iteration "
    echo "iteration $i;$(date -I) $(date +%T);stopTestrun" >> ~/log_idle.csv

    # cool down
    syncUp 30

    # Remove logs
    rm ~/.config/okularrc
    rm ~/.config/okularpartrc
    rm -r ~/.local/share/okular/*

    clear

done
